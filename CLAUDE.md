# TechNet — working notes

A flake-based NixOS configuration for a personal network of devices, joined over
WireGuard. See [README.md](README.md) for the network itself.

## Hosts

Each host is a `nixosConfigurations` entry in [flake.nix](flake.nix) composing
`nix/0-common` with one device directory.

| Host | Device | Modules |
| --- | --- | --- |
| `Odin` | laptop (x86_64) | `nix/0-common` + `nix/3-laptop` |
| `Heimdall` | server (x86_64) | `nix/0-common` + `nix/2-server` |
| `Ragnarok` | backup server (aarch64) | `nix/0-common` + `nix/1-backup-server` |
| `Thor` | phone | `nix/0-common` + `nix/5-phone` |

Host names are capitalised — `#Odin`, not `#odin`. The lowercase form declared in
[20-nixtool.nix](nix/3-laptop/1-system/20-nixtool.nix) is the SSH address
(`odin.technet`).

## Rebuilding

Deploys go through `nixtool`, which wraps `nixos-rebuild` with the flake path and
target host already resolved:

```sh
nixtool run maintenance/rebuild --host Odin --action switch
```

`nixtool` is installed by [6-nixtool.nix](nix/0-common/1-system/5-software/6-nixtool.nix)
and reads its config from `/etc/nixtool/nixtool-config.json`, rendered from
[20-nixtool.nix](nix/3-laptop/1-system/20-nixtool.nix). There is no
`nixtool-config.json` in the repo and no `nixtool.sh` wrapper — hosts, flake path
and installer credentials are all declared in Nix, so no `--config` flag is needed
and no credential is checked in.

| Action | Effect |
| --- | --- |
| `dry-activate` | Build and print what would change. **Always run this first.** |
| `switch` | Activate now and set as the boot default |
| `test` | Activate now, revert on next boot |
| `boot` | Activate on next boot only |
| `rollback` | Return to the previous generation |

### Run builds and deploys in the background

Always start `nix build` and `nixtool run maintenance/rebuild` as background
tasks — or hand them to a subagent — rather than blocking on them in the
foreground. Two reasons, and the second is the important one:

- They routinely outrun a foreground command timeout. An aarch64 closure under
  binfmt, or anything that has to compile ZFS against a new kernel, is tens of
  minutes; a foreground call gets killed at the limit and the output is lost.
- A foreground build blocks the conversation. Backgrounding it means you can
  keep giving instructions while it runs, instead of waiting for it to return.

Poll the task output rather than piping the build through `tail` — `tail`
buffers, so the log stays empty until the build finishes and progress is
invisible for the whole run.

One trap when cancelling: `pkill -f "nix build ..."` matches the pattern against
its own command line and kills the calling shell along with the build. Match on
something narrower, or kill by PID.

Other useful commands — `nixtool list` shows all of them:

```sh
nixtool run maintenance/flake-update              # bump flake.lock
nixtool run maintenance/export-dconf              # dump Cinnamon settings back into the repo
nixtool run maintenance/preview-generations --host Odin
```

If `nixtool` is not on PATH yet — a fresh machine, or a generation built before
the module landed — fall back to `nixos-rebuild` directly for the one deploy that
installs it:

```sh
sudo nixos-rebuild switch --flake .#Odin
```

Building without deploying, which is the fastest way to check a change compiles:

```sh
nix build --no-link .#nixosConfigurations.Odin.config.system.build.toplevel
```

Evaluating a single option, for checking what a module actually produced:

```sh
nix eval .#nixosConfigurations.Odin.config.services.xserver.displayManager.lightdm.enable
```

### Before deploying to Odin

`Odin` is the machine this repo is usually edited from, so a bad deploy takes out
the session you are working in. Always `dry-activate` first and read the unit list.
`would NOT stop the following changed units: display-manager.service` means the
graphical session survives; if the display manager *would* restart, expect to be
logged out.

### After deploying to Thor

**Always confirm phosh came back.** Anything that changes phoc, phosh or stevia
restarts `phosh.service`, and while it is down the phone is a black screen —
there is no login prompt behind it to fall back to. So finish every Thor deploy
with:

```sh
ssh beatlink@thor.technet 'systemctl is-active phosh.service' \
  || ssh beatlink@thor.technet 'sudo systemctl restart phosh.service'
```

Two things that look like they should cover this and do not. `Restart=always` is
already on the unit from the phosh module, and only covers phosh exiting on its
own — a deliberate stop is intentional as far as systemd is concerned. And a
switch's default stop-early/start-late handling of a changed service left the
screen black for the whole activation, which on this phone is minutes; that is
what `stopIfChanged = false` in
[6-display.nix](nix/5-phone/1-system/6-display.nix) is for.

A switch can also exit non-zero while the generation is live and everything is
running — a bind mount that impermanence no longer declares fails to unmount if
any process holds it, including a login shell whose cwd is inside it. Check
`readlink /run/current-system` and `systemctl --failed` before treating the
deploy as failed; clear the mount with `sudo umount -l <path>`, which detaches it
without killing whatever is holding it.

### Getting a tool onto a host without rebuilding

Diagnosing something usually needs a tool the host does not have. Rebuilding to
add one is slow and puts it in the closure permanently, so don't — fetch it for
the one command instead.

On the host, if it has network:

```sh
ssh beatlink@thor.technet 'nix run nixpkgs#vmtouch -- -v /some/path'
```

`nix run` builds or substitutes into the store and runs it, leaving nothing
installed. For repeated use in a script, resolve the path once and reuse it:

```sh
V=$(nix build --no-link --print-out-paths nixpkgs#vmtouch)/bin/vmtouch
```

For something built locally — a package from this repo, or an aarch64 build made
on Odin under binfmt — push the closure rather than rebuilding it there:

```sh
OUT=$(nix build --no-link --print-out-paths .#packages.aarch64-linux.default)
nix copy --to ssh://beatlink@thor.technet "$OUT"
ssh beatlink@thor.technet "$OUT/bin/whatever"
```

The store path is identical on both ends, so the path printed on Odin is the
path to run on Thor.

Two traps. Nix wraps most binaries, so the process name is not what you would
guess — `.epiphany-wrapp`, `.gtk4-demo-wrap` — and `pgrep -x epiphany` silently
matches nothing. Match on `pgrep -f`, or read `/proc/PID/comm` first. And a
graphical tool started over ssh needs the session's environment: use `launchapp`
(see [26-launchapp.nix](nix/5-phone/1-system/26-launchapp.nix)) rather than
exporting `WAYLAND_DISPLAY` by hand.

## Desktop environments

`nix/3-laptop/1-system/18-desktop-environment/default.nix` selects which are built.
Cinnamon and Hyprland can both be imported at once — LightDM lists Wayland sessions
alongside X11 ones, so all of them appear at login and you switch by logging out.

Constraints learned the hard way:

- **Only one display manager.** Cinnamon's module enables LightDM; the Hyprland
  module deliberately declares none. Enabling SDDM too gives two display managers
  fighting for the same VT.
- **Impermanence rejects a file claimed twice.** Both modules wanted
  `.config/mimeapps.list`; only Cinnamon persists it now.
- **LightDM defaults to `minimum-vt = 1`** in nixpkgs, which lands X on the same VT
  as the first getty and breaks Ctrl+Alt+F-key switching. The Cinnamon module
  overrides it to 7 via `extraConfig`, which is emitted after the module's own key
  and therefore wins.

### Hyprland

Configured entirely through home-manager, split across submodules imported at the
bottom of `hyprland/default.nix` — bar, launcher, notifications, lock screen and so
on are separate programs, since Hyprland is a compositor rather than a desktop.

- **Start components as systemd user services, not `exec-once`.** `withUWSM = true`
  binds the session to systemd, and home-manager already defines services for
  hyprpaper, hypridle, swaync and waybar. Listing them in `exec-once` as well runs
  two copies: swaync exits with "An instance is already running" and hits its
  restart limit. Only things with no service of their own belong in `exec-once`.
- **Config syntax moves between releases.** Check `hyprctl configerrors` after any
  change. As of 0.56: `windowrulev2` → `windowrule` with `match:` prefixes and
  explicit values, `suppressevent` → `suppress_event`, `dwindle:pseudotile` removed
  in favour of the `pseudo` dispatcher, and `togglesplit` is now
  `layoutmsg, togglesplit`.
- **Verify syntax against the running compositor** rather than guessing:
  `hyprctl keyword windowrule "match:class foo, float on"` answers `ok` or names the
  bad field.
- Stale processes survive a rebuild. After changing how a component is launched,
  kill the old one — a rebuild will not do it, and you get two bars.

## Secrets

sops-nix, with the host SSH key as the age identity. Secrets live in `secrets/`.
Nothing in this repo should contain a plaintext credential.
