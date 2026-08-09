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

A bad deploy takes out the session you are working in. Always `dry-activate`
first and read the unit list:

```sh
nixtool run maintenance/rebuild --host Odin --action dry-activate
```

`would NOT stop the following changed units: display-manager.service` means the
graphical session survives. If the display manager *would* restart, expect to be
logged out.

## Desktop environments

[`18-desktop-environment/default.nix`](../nix/3-laptop/1-system/18-desktop-environment/default.nix)
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

## Tang server

Odin hosts the tang server that unlocks Heimdall, Ragnarok and Thor, configured
in [`14-tang.nix`](../nix/3-laptop/1-system/14-tang.nix). It is **gated on an
unlocked desktop session**: `tangd.socket` stops when the screensaver locks.

The consequence is network-wide — a host that reboots while Odin is locked or
away will sit at its passphrase prompt rather than unlocking. That is
deliberate, but it makes Odin a dependency of every other host's boot.

Addresses served are set by `technet.tang.addresses`, defaulting to the
WireGuard address then the LAN one. Thor overrides this to its USB link address.

## nixtool

The module is imported for every host by
[`5-software.nix`](../nix/0-common/1-system/5-software.nix), but only Odin
enables it, in [`20-nixtool.nix`](../nix/3-laptop/1-system/20-nixtool.nix), which
renders `/etc/nixtool/nixtool-config.json`. Installer credentials are named as
sops paths rather than values, so nothing sensitive reaches the Nix store.

Every host is deployed from here. Its own command is under *Deploying to Odin*
above; the others are in [Heimdall](heimdall.md), [Ragnarok](ragnarok.md) and
[Thor](thor.md).

## Cross-architecture builds

`boot.binfmt.emulatedSystems` includes `aarch64-linux`, and `nix.settings.extra-platforms`
lists it too, so Odin can build closures for Ragnarok and Thor. This is qemu
emulation and therefore slow; Ragnarok is native aarch64 and could serve as a
remote builder via `nix.buildMachines` if that ever becomes worth setting up.

Note the limits of emulation: it works for *building*, but not for running
foreign-architecture tools that talk to the host kernel. See the disko
architecture note in [thor.md](thor.md#3-run-the-install).
