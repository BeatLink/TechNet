# Odin — laptop

| | |
| --- | --- |
| Platform | `x86_64-linux` |
| Modules | [`nix/0-common`](../nix/0-common) + [`nix/3-laptop`](../nix/3-laptop) |
| Address | `odin.technet`, `10.100.100.2` over WireGuard |

Odin is the workstation, and the machine this repo is normally edited and
deployed from. It is also where several network-wide roles live, so it is worth
treating as infrastructure rather than just a laptop.

## Deploying to Odin

X-Nix switches Odin on its own when `main` moves ([deploying](deploying.md)), and
a bad deploy takes out the session you are working in. Review a risky change with
a `dry-activate` through X-Nix and read the unit list.

`would NOT stop the following changed units: display-manager.service` means the
graphical session survives. If the display manager *would* restart, expect to be
logged out.

A switch that bumps the kernel restarts `nvidia-powerd` against the old loaded
module, so it fails, every later switch exits 4 and X-Nix rolls each one back:
generations climb while `/run/current-system` stays put. Compare `uname -r` with
`readlink /run/current-system/kernel`; rebooting into the newest generation
clears it.

## Desktop environments

[`18-desktop-environment/default.nix`](../nix/3-laptop/1-system/desktop-environment/default.nix)
selects which are built. Cinnamon and Hyprland can both be imported at once —
LightDM lists Wayland sessions alongside X11 ones, so all of them appear at login
and you switch by logging out.

Constraints learned the hard way:

- **Only one display manager.** Cinnamon's module enables LightDM; the Hyprland
  module deliberately declares none. Enabling SDDM too gives two display managers
  fighting for the same VT.
- **Impermanence rejects a file claimed twice.** Both modules wanted
  `.config/mimeapps.list`; only Cinnamon persists it now.
- **LightDM defaults to `minimum-vt = 1`** in nixpkgs, which lands X on the same
  VT as the first getty and breaks Ctrl+Alt+F-key switching. The Cinnamon module
  overrides it to 7 via `extraConfig`, which is emitted after the module's own
  key and therefore wins.

### Hyprland

Configured entirely through home-manager, split across submodules imported at the
bottom of `hyprland/default.nix` — bar, launcher, notifications, lock screen and
so on are separate programs, since Hyprland is a compositor rather than a
desktop.

- **Start components as systemd user services, not `exec-once`.** `withUWSM =
  true` binds the session to systemd, and home-manager already defines services
  for hyprpaper, hypridle, swaync and waybar. Listing them in `exec-once` as well
  runs two copies: swaync exits with "An instance is already running" and hits
  its restart limit. Only things with no service of their own belong in
  `exec-once`.
- **Config syntax moves between releases.** Check `hyprctl configerrors` after
  any change. As of 0.56: `windowrulev2` → `windowrule` with `match:` prefixes
  and explicit values, `suppressevent` → `suppress_event`, `dwindle:pseudotile`
  removed in favour of the `pseudo` dispatcher, and `togglesplit` is now
  `layoutmsg, togglesplit`.
- **Verify syntax against the running compositor** rather than guessing:
  `hyprctl keyword windowrule "match:class foo, float on"` answers `ok` or names
  the bad field.
- Stale processes survive a rebuild. After changing how a component is launched,
  kill the old one — a rebuild will not do it, and you get two bars.

## Packet Tracer

[`tools/packet-tracer.nix`](../nix/3-laptop/4-apps/tools/packet-tracer.nix)
installs `cisco-packet-tracer_9` from nixpkgs, but Cisco only serves the
installer behind a NetAcad login, so nixpkgs cannot fetch it and the build stops
with `Unfortunately, we cannot download file ...` until the `.deb` is in the
store. Once, before the first deploy and again after any version bump:

1. Sign in at <https://www.netacad.com/resources/lab-downloads> and download
   `CiscoPacketTracer_901_Ubuntu_64bit.deb` (the name and hash the package
   expects are in its nixpkgs `package.nix`).
2. Keep it on Heimdall, in `/Storage/Services/Attic/build_artifacts/`, beside the
   cache, since X-Nix builds Odin's closure there and that build fails when this
   one path cannot be fetched. Odin no longer builds, so it needs no copy.
3. Add it to Heimdall's store and root it there, then deploy as usual:

```sh
ssh heimdall
P=$(sudo nix-store --add-fixed sha256 /Storage/Services/Attic/build_artifacts/CiscoPacketTracer_901_Ubuntu_64bit.deb)
sudo nix-store --add-root /nix/var/nix/gcroots/packet-tracer-deb --indirect --realise "$P"
```

`build_artifacts` sits under Attic's `.nobackup` marker, so it is not backed up:
losing it means downloading the `.deb` again. The command is `packettracer9`;
the AppImage forces `xcb`, so it runs under Xwayland on Wayland sessions.

The root is what makes it survive, since nothing in the built system refers to
it. The deb and the package's closure are also in the Attic cache, so a host
that has never had the file substitutes them instead. The cache drops a path no
host has fetched for 30 days, so push them again with `attic push technet
<path>` if that happens or after a version bump.

## Tang server

Odin hosts the tang server that unlocks Heimdall, Ragnarok and Thor, configured
in [`tang.nix`](../nix/3-laptop/1-system/tang.nix). It is **gated on an
unlocked desktop session**: `tangd.socket` stops when the screensaver locks.

The consequence is network-wide — a host that reboots while Odin is locked or
away will sit at its passphrase prompt rather than unlocking. That is
deliberate, but it makes Odin a dependency of every other host's boot.

Addresses served are set by `technet.tang.addresses`, defaulting to the
WireGuard address then the LAN one. Thor overrides this to its USB link address.

## nixtool

The module is imported for every host by
[`nixtool.nix`](../nix/0-common/1-system/software/nixtool.nix), but only Odin
enables it, in [`nixtool.nix`](../nix/3-laptop/4-apps/technet/nixtool.nix), which
renders `/etc/nixtool/nixtool-config.json`. Installer credentials are named as
sops paths rather than values, so nothing sensitive reaches the Nix store.

nixtool installs hosts but no longer deploys them; that is X-Nix's job
([deploying](deploying.md)).

### Install credentials

Odin installs every host, so it holds every host's `ENCRYPTION_KEY`,
`SSH_HOST_KEY` and `SSH_INITRD_KEY`. The host keys matter as much as the
passphrase: `sops.age.sshKeyPaths` derives each host's age identity from
`ssh_host_ed25519_key`, so a reinstall that generates a fresh one leaves the
machine unable to decrypt its own secrets.

nixtool decrypts every credential itself with your own age key, so no host key
can read them. Every host's disk passphrase lives as `<host>_encryption_key` in
[`nixtool.yaml`](../secrets/admin/nixtool.yaml), beside every host's SSH host
and initrd keys. No host holds a copy of its own: `rebind-clevis <host>` on Odin
pipes it over SSH into the host's `rebind-clevis` when its bindings need
renewing.

`SSH_PASSWORD` is not stored. It is whatever the target's live installer was
given that boot, so `install-nixos` prompts for it.

## Cross-architecture builds

`boot.binfmt.emulatedSystems` includes `aarch64-linux`, and `nix.settings.extra-platforms`
lists it too, so Odin can build Thor's closure. This is qemu emulation and
therefore slow.

Note the limits of emulation: it works for *building*, but not for running
foreign-architecture tools that talk to the host kernel. See the disko
architecture note in [thor.md](thor.md#3-run-the-install).

## Claude Code

Every MCP server Claude Code uses is declared in
[`claude-mcp`](../nix/3-laptop/4-apps/programming/claude-mcp/default.nix). Tokens
live in `secrets/3-laptop/claude-mcp.yaml`, and a sops template linked to
`/etc/claude-code/managed-mcp.json` fills them in; Claude Code treats that file
as the only server list, so `claude mcp add` has no effect. Add a token with
`set-mcp-token <server>` after adding the server to its `APPS`. Trilium's servers
take the raw ETAPI token as `Authorization`, the X-apps `Bearer <token>`.

[`app-slices.nix`](../nix/3-laptop/1-system/app-slices.nix) places desktop apps
in user slices through prefix drop-ins on the transient `app-<id>-<pid>.scope`
units GLib creates. An app started outside GLib, such as one restored by the
session, stays in `session-N.scope`. The VS Code extension's
`claudeProcessWrapper` gives each Claude session its own scope in
`agents.slice`, capped by [`memory-guard.nix`](../nix/3-laptop/1-system/memory-guard.nix).

## Troubleshooting

- **IO pressure.** Rank `/sys/fs/cgroup/**/io.pressure` first, then
  `/proc/<pid>/io`. Syncthing's own index database was the culprit once; its
  `counts` table gives live and deleted totals at once, where scanning `files`
  takes minutes.
- **Wireless keyboard lag** is 2.4 GHz contention: the MT7921's Wi-Fi shares an
  antenna with its Bluetooth. Check the band with
  `nmcli -f ACTIVE,SSID,CHAN,FREQ device wifi list`; a switch does not
  re-associate until the connection goes down and up.
- **A WebKitGTK app dies with SIGFPE** and only a coredump, in
  `WebKit::DisplayLink::platformInitialize`: a connected but unlit output (the
  closed lid's `eDP-1`) reports a refresh rate of 0. The fix is in
  [`linux-sidebar.nix`](../nix/3-laptop/4-apps/tools/linux-sidebar.nix).
- **An app moved off Flatpak** that cannot find its files may carry
  `~/.var/app/…` paths in its own database or config, as itch did in
  `~/.config/itch/db/butler.db`. Grep for `.var/app` before changing persistence.
- **Cinnamon.** `gdbus call --session --dest org.Cinnamon --object-path /org/Cinnamon --method org.Cinnamon.Eval '<js>'`
  runs JavaScript in the live session. Re-enabling an applet reuses its cached
  module, so new `applet.js` code needs
  `imports.ui.extension.reloadExtension('<uuid>', imports.ui.extension.Type.APPLET)`.
  Muffin reads `cinnamon-monitors.xml` only at session start, numbers monitors
  in block order, and puts panels on the first block but hot corners on the
  `<primary>` output, so the two must name the same output.
