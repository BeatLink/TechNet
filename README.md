# TechNet

The TechNet is my personal network of computing devices, all connected via a WireGuard VPN network.

[![Bump flake.lock](https://github.com/BeatLink/TechNet/actions/workflows/main.yml/badge.svg)](https://github.com/BeatLink/TechNet/actions/workflows/main.yml)

Outstanding work is tracked in [TODO.md](TODO.md).

## Hosts

Each host is a `nixosConfigurations` entry in [flake.nix](flake.nix), composing
[`nix/0-common`](nix/0-common) with one device directory.

| Host | Device | Role | Docs |
| --- | --- | --- | --- |
| `Odin` | laptop (x86_64) | workstation, tang server, deploy host | [docs/odin.md](docs/odin.md) |
| `Heimdall` | server (x86_64) | WireGuard hub, DNS, services | [docs/heimdall.md](docs/heimdall.md) |
| `Ragnarok` | Rock64 (aarch64) | backups | [docs/ragnarok.md](docs/ragnarok.md) |
| `Thor` | PinePhone (aarch64) | phone | [docs/thor.md](docs/thor.md) |

Host names are capitalised — `#Odin`, not `#odin`. The lowercase form declared in
[20-nixtool.nix](nix/3-laptop/1-system/20-nixtool.nix) is the SSH address
(`odin.technet`).

## Rebuilding

Deploys go through `nixtool`, which wraps `nixos-rebuild` with the flake path and
target host already resolved:

```sh
nixtool run maintenance/rebuild --host Odin --action switch
```

`nixtool` is installed by
[6-nixtool.nix](nix/0-common/1-system/5-software/6-nixtool.nix) and reads its
config from `/etc/nixtool/nixtool-config.json`, rendered from
[20-nixtool.nix](nix/3-laptop/1-system/20-nixtool.nix). There is no
`nixtool-config.json` in the repo and no `nixtool.sh` wrapper — hosts, flake path
and installer credentials are all declared in Nix, so no `--config` flag is
needed and no credential is checked in.

| Action | Effect |
| --- | --- |
| `dry-activate` | Build and print what would change. **Always run this first.** |
| `switch` | Activate now and set as the boot default |
| `test` | Activate now, revert on next boot |
| `boot` | Activate on next boot only |
| `rollback` | Return to the previous generation |

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

Building without deploying, the fastest way to check a change compiles:

```sh
nix build --no-link .#nixosConfigurations.Odin.config.system.build.toplevel
```

## Installing

`install/install-nixos` provisions a host over SSH with `nixos-anywhere`.
Credentials come from sops, so nothing is typed:

```sh
nixtool run install/install-nixos --host <Host> --ssh-target root@<ip>
```

Targets that cannot be installed that way — anything whose own OS lacks `kexec`,
or that has no usable network — use `install/install-local` against a disk
attached to the deploying machine. Thor is installed this way; see
[docs/thor.md](docs/thor.md#installing).

## Secrets

sops-nix, with the host SSH key as the age identity. Secrets live in `secrets/`,
keyed per host by the rules in [.sops.yaml](.sops.yaml). Nothing in this repo
should contain a plaintext credential.

Host keys are seeded at install time, so a reinstalled host keeps the identity
its secrets are encrypted to. If a host key is lost, its age key must be replaced
in [.sops.yaml](.sops.yaml) and the affected files re-encrypted with
`sops updatekeys`.

## Unlocking

Root pools use ZFS native encryption. Clevis unlocks them against the tang server
on Odin, which is **gated on Odin's desktop session being unlocked** — so a host
rebooting while Odin is locked or away will wait at its passphrase prompt. See
[docs/odin.md](docs/odin.md#tang-server).

ZFS native encryption has exactly one wrapping key per encryption root and no
spare keyslots. A lost passphrase means a reinstall, so every host that has one
should have it stored in sops.
