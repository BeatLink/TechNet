# TechNet

The TechNet is my personal network of computing devices, all connected via a WireGuard VPN network.

[![Bump flake.lock](https://github.com/BeatLink/TechNet/actions/workflows/main.yml/badge.svg)](https://github.com/BeatLink/TechNet/actions/workflows/main.yml)

## Hosts

Configured by this repo, one flake output each:

| Host | Role | Platform | Modules |
| --- | --- | --- | --- |
| [Heimdall](docs/heimdall.md) | Server — WireGuard hub, DNS, services, binary cache | `x86_64-linux` | [`2-server`](nix/2-server) |
| [Odin](docs/odin.md) | Laptop — workstation, deploy host, tang server | `x86_64-linux` | [`3-laptop`](nix/3-laptop) |
| [Ragnarok](docs/ragnarok.md) | Backup server — Rock64 SBC, off site | `aarch64-linux` | [`1-backup-server`](nix/1-backup-server) |
| [Thor](docs/thor.md) | PinePhone | `aarch64-linux` | [`5-phone`](nix/5-phone) |

Every host also imports [`0-common`](nix/0-common).

## Other devices

On the network, but not configured from here:

- **Hela** — tablet. [`4-tablet`](nix/4-tablet) is a placeholder.
- **ThorX** — Android phone. Its Syncthing is configured on the device.
- **[Loki](docs/smartwatch.md)** — PineTime smart watch, bio-monitor and TechNet
  remote control. Pairs over Bluetooth rather than joining the tunnel.
- **Home automation** — ESPHome lights, sensors, an IR bridge and two smart
  sockets, defined under
  [`esphome/devices`](nix/2-server/3-services/home-automation/esphome/devices)
  and addressed in [Architecture](docs/architecture.md#addresses).

Off the network entirely: a tech kit of computer repair tools, peripherals and
accessories.

## Documentation

- [Architecture](docs/architecture.md) — filesystem paradigm and network
  addressing, common to every host
- [Tow-Boot](docs/tow-boot.md) — the firmware fork Thor and Ragnarok boot
  through, and how to build and deploy it
- [Thor — Firefox tuning](docs/thor-firefox.md)
- [Thor — waypipe apps](docs/thor-waypipe-apps.md) — which of Odin's
  applications are worth a launcher on the phone, and why
- [TODO](TODO.md) — outstanding work, most blocking first
