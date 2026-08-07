# TechNet

Flake-based NixOS config for a personal network joined over WireGuard. See
[README.md](README.md).

## Hosts

Each host is a `nixosConfigurations` entry in [flake.nix](flake.nix) composing
`nix/0-common` with one device directory. Names are capitalised — `#Odin`, not
`#odin`; lowercase is the SSH address (`odin.technet`).

| Host       | Device                  | Modules                                |
| ---------- | ----------------------- | -------------------------------------- |
| `Odin`     | laptop (x86_64)         | `nix/0-common` + `nix/3-laptop`        |
| `Heimdall` | server (x86_64)         | `nix/0-common` + `nix/2-server`        |
| `Ragnarok` | backup server (aarch64) | `nix/0-common` + `nix/1-backup-server` |
| `Thor`     | phone                   | `nix/0-common` + `nix/5-phone`         |

## Rebuilding

**Always `dry-activate` first. Always run builds and deploys in the background**
— foreground calls block the conversation and die at the command timeout. Poll
the task; `tail` buffers and shows nothing. Cancel by PID (`pkill -f "nix build"`
kills the calling shell).

```sh
nixtool run maintenance/rebuild --host Odin --action dry-activate
#   ... --action switch | test | boot | rollback
nixtool list                                      # all commands
nixtool run maintenance/flake-update              # bump flake.lock
nixtool run maintenance/export-dconf              # dump Cinnamon settings into the repo

sudo nixos-rebuild switch --flake .#Odin          # only if nixtool is not on PATH yet
nix build --no-link .#nixosConfigurations.Odin.config.system.build.toplevel
nix eval .#nixosConfigurations.Odin.config.services.xserver.displayManager.lightdm.enable
```

**Odin** is where this repo is edited, so a bad deploy kills the current session.
In the `dry-activate` unit list, `would NOT stop the following changed units:
display-manager.service` means the graphical session survives.

**Thor** goes to a black screen with no login prompt whenever phoc, phosh or
stevia change, and `Restart=always` does not cover a deliberate stop. Confirm it
came back:

```sh
ssh beatlink@thor.technet 'systemctl is-active phosh.service' \
  || ssh beatlink@thor.technet 'sudo systemctl restart phosh.service'
```

A switch can exit non-zero while the generation is live — a bind mount
impermanence no longer declares will not unmount while a process holds it. Check
`readlink /run/current-system` and `systemctl --failed`; clear with `sudo umount
-l <path>`.

### Tools on a host without rebuilding

```sh
ssh beatlink@thor.technet 'nix run nixpkgs#vmtouch -- -v /some/path'

OUT=$(nix build --no-link --print-out-paths .#packages.aarch64-linux.default)
nix copy --to ssh://beatlink@thor.technet "$OUT"   # store path is identical both ends
ssh beatlink@thor.technet "$OUT/bin/whatever"
```

Nix truncates wrapped binary names (`.epiphany-wrapp`), so use `pgrep -f`, not
`-x`. Graphical tools over ssh need `launchapp`
([26-launchapp.nix](nix/5-phone/1-system/26-launchapp.nix)), not a hand-exported
`WAYLAND_DISPLAY`.

## Desktop environments

`nix/3-laptop/1-system/18-desktop-environment/default.nix` selects which are
built; Cinnamon and Hyprland coexist and switch by logging out.

- **One display manager only.** Cinnamon enables LightDM, Hyprland declares none.
- **Impermanence rejects a file claimed twice** — only Cinnamon persists
  `.config/mimeapps.list`.
- **LightDM's `minimum-vt = 1` default** breaks Ctrl+Alt+F-key switching; the
  Cinnamon module overrides it to 7.

Hyprland is configured through home-manager submodules imported at the bottom of
`hyprland/default.nix`.

- **Components go in systemd user services, not `exec-once`** — home-manager
  already defines hyprpaper, hypridle, swaync and waybar; both runs two copies.
- **Check `hyprctl configerrors` after any change**; syntax moves between
  releases. Verify against the running compositor: `hyprctl keyword windowrule
  "match:class foo, float on"` answers `ok` or names the bad field.
- **Kill stale processes** after changing how a component launches; a rebuild
  won't, and you get two bars.

## Secrets

sops-nix, host SSH key as the age identity, secrets in `secrets/`. No plaintext
credential in this repo.

## Comments

**Default: no comments**, in new files and edits alike. Mechanism, history,
measurements, what upstream does, what was tried and rejected, and rationale for
a settled choice go in the chat response, not the file.

Three exceptions, and nothing else:

**1. A file header** of at most 5 lines: the module's purpose and any hazard.

**2. Section separators.** Banners for major sections, dashes for subsections and
functions. Indentation plus text plus separator = exactly 150 characters.

```nix
# Section Name ##########################

# Subsection name ------------------------------
```

**3. A one-line hazard note** on a setting an intermediary programmer would get
wrong.

```nix
# 160 is unity, not a maximum; 192 is +24dB and clips into static
amixer -c "$card" cset name='AIF1 DA0 Playback Volume' 160

# Needed to prevent a dependency loop
DefaultDependencies = "no";

# Might be a security risk, PSK in initrd, consider certificate based auth
sops.templates."wpa_supplicant-initrd.conf" = { ... };
```

One line, no quoted output, on the line that would need to change rather than in
the header. Only where the reader would act differently without it — the test is
whether someone editing this line would break something, not whether the history
is interesting. Say what the hazard is, not the mechanism, and name the way out.
