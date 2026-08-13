# Heimdall — server

| | |
| --- | --- |
| Platform | `x86_64-linux` |
| Modules | [`nix/0-common`](../nix/0-common) + [`nix/2-server`](../nix/2-server) |
| Address | `heimdall.technet`, `10.100.100.1` over WireGuard |

Heimdall is the always-on server and the hub of the network. It terminates the
WireGuard tunnel that every other host dials into, serves DNS, and runs the
services in [`3-services`](../nix/2-server/3-services).

## Role in the network

Peers connect *to* Heimdall rather than to each other, so it is the one host
whose reachability everything else depends on. Its initrd WireGuard probe
therefore targets the LAN gateway rather than a peer — a peer may legitimately be
down or still locked, so it is not a usable health signal. See
[`initrd-wireguard.nix`](../nix/0-common/1-system/6-networking/2-initrd-wireguard.nix).

DNS for the network is Pi-hole at `10.100.100.1`, backed by Unbound.

## Services

Grouped by directory under [`3-services`](../nix/2-server/3-services):

| Group | Services |
| --- | --- |
| `networking` | nginx, nginx-vhosts, pi-hole, unbound |
| `personal-info-and-files` | blockurl, radicale, syncthing, trilium |
| `fun-and-media` | calibre-web-automated, freshrss, gallery-dl, jackett, openbooks, qbittorrent, vlc |
| `home-automation` | esphome, frigate, home-assistant, lnxlink, mosquitto, traccar |
| `monitoring` | homepage, vigil |
| `technet` | attic |
| `backups` | borg, borgmatic, stremio-export |

Port assignments are tracked in
[`_Port Maps.md`](../nix/2-server/3-services/_Port%20Maps.md). Services are
reverse-proxied through nginx; a new service usually needs a vhost entry as well
as its own module.

## Binary cache

Heimdall runs [Attic](../nix/2-server/3-services/technet/attic.nix) as the
network's binary cache at `https://attic.heimdall.technet/`. Every host
substitutes from the `technet` cache, configured in
[`attic-cache.nix`](../nix/0-common/1-system/software/attic-cache.nix); pushing
into it needs a write token, which is not handed out by default.

Caches and tokens have no declarative provisioning. They are created once with
`atticd-atticadm`, which runs the admin tool as the service user:

```sh
atticd-atticadm make-token --sub odin --validity '1y' --pull 'technet' --push 'technet'
```

The store itself lives on the data pool via
`environment.persistence."/Storage/Services/Attic"`, and carries a `.nobackup`
marker so borgmatic skips it — the contents are reproducible and would otherwise
dominate the repo.

## Unlocking

Heimdall's root pool is unlocked by clevis against Odin's tang server, enabled in
[`clevis.nix`](../nix/2-server/1-system/clevis.nix). The passphrase is stored
in `secrets/2-server/clevis.yaml`, so it is recoverable — unlike a host where
clevis is disabled.

Because tang runs on Odin and stops when Odin's session locks, **Heimdall will
not come back from a reboot unless Odin is awake and unlocked**. The
`clevis-retry` service keeps trying in the background rather than blocking the
boot, so it will unlock on its own once tang appears.

Initrd WireGuard plus initrd SSH mean a stuck boot can be fixed remotely, which
is the reason that combination exists.

## Rebuilding

```sh
nixtool run maintenance/rebuild --host Heimdall --action dry-activate
nixtool run maintenance/rebuild --host Heimdall --action switch
```

Restarting a service group tends to be more disruptive here than on other hosts —
read the unit list from `dry-activate` before switching.
