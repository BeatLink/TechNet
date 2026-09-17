# Build cache audit — overlays and local compilation

| | |
| --- | --- |
| Date | 2026-09-17 |
| nixpkgs | `b1b875982b` (2026-09-16) |
| Measured on | Odin, with `cache.nixos.org` and `https://attic.heimdall.technet/technet` both reachable |
| Status | Every item under *Work done* at the end of this file has been applied; the findings above describe the state that prompted them |

Every `nixpkgs.overlays`, `override` and `overrideAttrs` site in the tree, assessed for
whether it forces a package to be compiled locally instead of substituted, plus the
non-overlay causes of the same thing.

## Method

- `nix build --dry-run` on all four host toplevels, with both substituters live.
- Signature audit of Odin's running system closure: a path carrying no `cache.nixos.org-1`
  signature was built inside the fleet rather than fetched from Hydra.
- Fan-out per overlay from `nix-store -q --referrers-closure`, intersected with that set.
- Cache membership confirmed per path with `<hash>.narinfo` against both substituters.

Figures describe the caches as they were on the date above. The cost immediately after a
nixpkgs bump is larger, because the Attic is then cold for everything an overlay touches.

## Headline

| Host | derivations to build | of which real compiles |
| --- | --- | --- |
| Odin | 0 (current system already built) | — |
| Heimdall | 109 | `homeassistant-2026.9.2`, frigate custom component, `lnxlink`, `calibre-web-automated` |
| Thor | 92 | `phosh-0.56.0`, `phoc-0.56.0`, `phosh-mobile-settings-0.56.0`, `sops-install-secrets` |
| Ragnarok | 210 | `sops-install-secrets`, plymouth themes |

Everything else in those counts is config derivations — units, `etc`, activation scripts —
which are always local and cost nothing.

Odin's closure: **870 of 3221 paths (5.04 GiB) carry no cache.nixos.org signature**, so they
were built inside the fleet.

## 1. Overlays that were dead code — both deleted

`nix/3-laptop/overlays.nix` and `nix/2-server/overlays.nix` were removed on the date of
this audit, along with their `imports` lines. Odin and Heimdall both still evaluate, and
Heimdall's dry-run is unchanged at 109 derivations with `aiohttp` and `python-ulid` still
substituted rather than built. The findings below are the reasoning, kept as the record.

### `nix/3-laptop/overlays.nix` — no-op — **deleted**

The static `libcap_ng` `doCheck = false` produces a byte-identical derivation at the pinned
nixpkgs. With and without the overlay:

    pkgsStatic.libcap_ng.drvPath  = /nix/store/qi392zjamjz2v6mnp4hqg3wirvybhdsd-libcap-ng-static-…
    pkgsStatic.qemu-user.drvPath  = /nix/store/fbhvvxnn63pz9j9w905n165yz4p4f0zb-qemu-user-static-…

Upstream already disables that check. `qemu-user-static` answers 200 on cache.nixos.org at
the current hash, so nothing here forced a build.

### `nix/2-server/overlays.nix` — ineffective, and no longer needed — **deleted**

It never reaches Vigil. The overlaid `python3.12-aiohttp` (`8b9mzphi…`, `doInstallCheck=""`)
has **zero referrers**. `config.services.vigil.package` (`hs3k2bv1…`) depends on the untouched
`3mi33qgb…` aiohttp and `jki9apb4…` python-ulid, tests still on.

The reason is structural: Vigil comes from `inputs.vigil.nixosModules.default`, and a flake
input's packages are built inside that flake's own nixpkgs instantiation. `nixpkgs.overlays`
set in a NixOS module never applies to them. A broken transitive Python dependency of Vigil
has to be fixed in the Vigil flake.

It is also unnecessary now: both untouched packages are satisfied from the caches in
Heimdall's dry-run.

## 2. Overlays that are load-bearing and cheap

| Site | Why it stays |
| --- | --- |
| `nix/0-common/1-system/software/overlays.nix` | `sops-nix/pkgs/sops-install-secrets/default.nix` still takes `buildGo125Module`, and evaluating that attribute in the pinned nixpkgs throws. No extra cost: sops-nix follows nixpkgs, so the package is built per-arch regardless. Note it is a fleet-wide alias silently shifting a Go major version — it will stop being noticed once sops-nix catches up. |
| `nix/5-phone/1-system/calls.nix` | Required. The test suite nests user namespaces under bwrap, which qemu-user cannot emulate, so an aarch64 build on Odin dies there. |
| `hyprland/{lid,overview,edge-snap,sounds,scripts}.nix` | `writeShellApplication` only. No compilation. |
| `0-common/4-apps/technet/waypipe.nix` | One meson flag on a leaf package. |
| `5-phone/1-system/clevis.nix`, `5-phone/3-apps/native/phone.nix`, `5-phone/3-apps/waydroid/gnss/default.nix` | Single leaf packages, no fan-out. |

## 3. Overlays that cost real build time

| Site | Local paths on Odin | Notes |
| --- | --- | --- |
| `cinnamon-bump.nix` | **46** downstream of `xapp`; 27 of `muffin`, 26 of `cinnamon` | Ten packages re-sourced at Mint 6.7.x plus two local patches. `muffin-6.7.4` is 404 on both cache.nixos.org and the Attic. The largest overlay in the tree. |
| `phosh-bump.nix` | aarch64 only | `phosh`, `phoc` and `phosh-mobile-settings` are all "will be built" for Thor today; `wlroots_0_20` and `stevia` are already in the Attic. |
| `steam.nix` | 6 (gamemode) + ~20 | The `millennium` input builds its Rust tree crate by crate — `oxc_*`, `phf_*`, `rmp*` all trace back to `millennium-3.4.1`'s `cargo-vendor-dir`. |
| `nemo/default.nix` (`nemo-preview`) | 7 | One `preFixup` line costs the whole wrapper chain. |
| `quodlibet.nix` + `2-server/4-apps/phone-apps.nix` | 7 | Same variant on both hosts, so the Attic shares one build. |
| `vscodium.nix` (`poetry`) | 7 | `doCheck = false` is what takes it off Hydra. |
| `home-assistant/default.nix` (frigate) | — | Three deselected tests; HA and the component are built on Heimdall anyway. |

### What a rollback would cost

Both bumps are standing multi-package rebuilds, so the obvious saving is to drop them and
take nixpkgs' versions. What that gives up, from the evidence in each overlay's own header:

**`cinnamon-bump` → nixpkgs 6.6.3.** The X11 session — `defaultSession` on Odin, because
Cinnamon Wayland has no ScreenCast portal and screen sharing needs one — is nixpkgs' own
tested configuration and loses nothing measured. The whole cost falls on the Wayland session:

- **Hardware GL.** `muffin` 6.6.3 advertises `zwp_linux_dmabuf_v1` at version 3 and no
  `wl_drm`, and Mesa 26 learns the render device only from dmabuf feedback v4, so every GL
  client on that session — Xwayland included — falls back to llvmpipe.
- **The desktop background.** 6.6's `csd-background` paints the X11 root pixmap, which
  nothing composites on Wayland; the `gtk-layer-shell` build that fixes it is part of the bump.
- **Status icons.** `xapp` only puts them on layer shell at 3.3.
- **The in-process lock screen**, back to `cinnamon-screensaver`; the
  `security.pam.services.cinnamon` entry in the same file goes with it.
- **Both local patches**, which matter only on the same session: Xwayland being handed the
  dGPU by `wl_drm`, and `csd-background` segfaulting on a monitor GDK has not sized yet.

So this is the one rollback the measurements make a case for — 46 paths, the largest overlay
in the tree — but only if the Wayland session is not wanted. That is a decision about intent,
not one the figures settle.

**`phosh-bump` → nixpkgs 0.54.0.** Not available. On 0.54 Thor has no on-screen keyboard and
no screen rotation, both verified live rather than assumed, and the missing keyboard includes
the lock screen — phosh hides the PIN keypad to make room for a surface that never appears.
The two local patches go too: a use-after-free in `on_startup_timeout` that takes the session
down, and the discarded DBus pid that gives every app 5s to start instead of 27s, on a phone
where Files needs 14.7s warm and 21.8s cold. nixpkgs' 0.54 also ships
`xdg-desktop-portal-phosh` 0.55 in the same closure, so the rollback target is not an
internally consistent stack either. The aarch64 build cost is real, but it belongs to the
cache gap in §5, not to this overlay.

## 4. Non-overlay causes, which outweigh the overlays

1. **`inputs.nixpkgs.follows = "nixpkgs"` on 28 of 30 flake inputs.** The biggest structural
   driver: every one of those flakes' packages is re-derived against the current nixpkgs and
   can never be substituted from its own upstream cache.

   Dropping the follows only helps where three things hold at once: the input publishes a
   cache, this repo consumes the flake's *own* output rather than re-deriving it, and the
   avoided build is worth a second nixpkgs in the lock. Checking every input against that:

   | Input | Publishes a cache | Verdict |
   | --- | --- | --- |
   | `pinephone-kernel` | yes, its own CI | already opted out — a multi-hour aarch64 kernel |
   | `claude-code` | `claude-code.cachix.org` | **follows dropped** — see *Work done* |
   | `sops-nix` | `cache.thalheim.io` | keep following: its module builds `sops-install-secrets` from the *system* `pkgs`, so its own cache can never answer |
   | `nix-vscode-extensions` | nix-community | keep following: that cache holds their CI checks, not the 25 extensions this repo installs |
   | everything else | no | keep following; the Attic is what shares these |

2. **Unfree packages Hydra does not build** — `nvidia-x11-595.99.02` (784 MiB, 404 on both
   caches), `cisco-packet-tracer` (816 MiB), `discord-unwrapped` (660 MiB), `claude-desktop`
   (526 MiB), `steam-unwrapped`, `itch`, `stremio`. Mostly unpack and patchelf rather than
   compilation, but they are most of the 5.04 GiB.
3. **The `boot.binfmt` static chain** on Odin — `qemu-user-static` (257 MiB), `glib-static`,
   `gnutls-static`, `libtasn1-static`. Cheaper than it looks: `qemu-user-static` is on
   cache.nixos.org at the current hash.
4. **`nix-index-with-full-db`** regenerates `index-x86_64-linux` (102 MiB) locally.
5. **25 VSCodium extensions** through `nix-vscode-extensions` — download-only fixed-output
   derivations, roughly 600 MiB, none on cache.nixos.org.

## 5. The aarch64 cache gap — closed

`cache-preseed.nix` warmed the Attic nightly for x86_64 only. `technet.atticPush.enable` was
true on Odin and Heimdall and **false on Thor and Ragnarok**, while `auto-upgrade.nix` runs a
`switch` with `allowReboot` weekly on all four hosts.

So an aarch64 path entered the Attic only when someone deployed Thor or Ragnarok from Odin
under binfmt first. If they had not, Thor's Saturday auto-upgrade compiled `phosh`, `phoc` and
`phosh-mobile-settings` on the phone itself — which was the state at the time of this audit,
all three being in Thor's build list.

Both halves are now fixed; see *Work done*.

## Work done

| # | Change | Where |
| --- | --- | --- |
| 1 | Deleted the no-op static `libcap_ng` overlay | `nix/3-laptop/overlays.nix`, import in `nix/3-laptop/default.nix` |
| 2 | Deleted the python312 test-skipping overlay | `nix/2-server/overlays.nix`, import in `nix/2-server/default.nix` |
| 3a | Thor and Ragnarok now push what they build | `nix/5-phone/1-system/software.nix`, `nix/1-backup-server/1-system/software.nix` |
| 3b | Heimdall emulates aarch64 and preseeds all four hosts nightly | `nix/2-server/3-services/technet/cache-preseed.nix` |
| 4 | Overlay no-op warning, raised during every rebuild | `nix/0-common/1-system/software/overlay-lint.nix` |
| 5 | `claude-code` no longer follows nixpkgs, and is taken from its own flake | `flake.nix`, `nix/0-common/4-apps/tools/claude-code.nix` |

### The overlay no-op warning

`technet.overlayLint.enable` (default on) compares every attribute any overlay in
`config.nixpkgs.overlays` defines against the same attribute in a nixpkgs imported with no
overlays at all, and emits a `warnings` entry for each one whose `drvPath` is identical:

    evaluation warning: overlay no-op: pkgs.hello builds the same derivation as nixpkgs' own,
    so this repo's override of it can be removed.

The overlay list is enumerated automatically — applying an overlay forces only the attribute
*names* it sets, never their values — so a new override is covered without registering it
anywhere.

Limits worth knowing:

- Only the top-level package set is compared. An override that exists for a variant set
  (`pkgsStatic`, a python package set) is invisible to it, which is exactly the case the
  deleted `libcap_ng` overlay was: it had to be proven no-op by hand.
- Attributes that are not derivations are skipped, so the `buildGo125Module` shim is never
  checked.
- It costs one extra nixpkgs instantiation: measured at **+7.7 s and +280 MB** on a cold
  evaluation of Odin's toplevel (35.0 s → 42.7 s). One line turns it off per host.

### The claude-code change

The input was declared in `flake.nix` but never referenced, so `pkgs.claude-code` came from
nixpkgs and was rebuilt locally on every bump (216 MiB, 404 on both caches). It now resolves
to `inputs.claude-code.packages.<system>.claude-code` — the flake's *own* output, which is
what its CI signs — and the cache is added to `nix.settings`. Verified: that path is a 200 on
`claude-code.cachix.org`, its five runtime references are all on `cache.nixos.org`, and a
dry-run now reports it as a 98.2 MiB fetch rather than a build.

Their CI builds linux-x64 and darwin only, so an aarch64 host asking for this package would
still build it. Nothing on Thor or Ragnarok does.

## Still open

- `flake.nix` still defines `apps.lint` from `./lint/report.sh`, which commit `0faafb6b`
  ("Remove unnecessary files") deleted. Anything that evaluates the flake's `apps` —
  `nix flake check`, `nix flake show`, `nix run .#lint` — fails with
  `Path 'lint/report.sh' does not exist in Git repository`. The host configurations are
  unaffected.
- `cinnamon-bump` and `phosh-bump` remain the two standing multi-package rebuilds. They are
  correct today; re-check them on each nixpkgs bump, which the warning above will not do for
  you, because a version bump is a real change rather than a no-op.
