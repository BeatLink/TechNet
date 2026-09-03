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
| `home-automation` | esphome, frigate, home-assistant, lnxlink, mosquitto |
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

Caches and tokens have no declarative provisioning — they are created once by
hand. `atticd-atticadm` runs the admin tool as the service user and mints
tokens; the cache itself is created through the API with one of those tokens:

```sh
# On Heimdall. A bootstrap token, then the cache, then the key the fleet trusts.
atticd-atticadm make-token --sub bootstrap --validity '1h' \
    --create-cache 'technet' --configure-cache 'technet' \
    --configure-cache-retention 'technet' --push 'technet' --pull 'technet'
attic login technet https://attic.heimdall.technet/ <token>
attic cache create technet
attic cache configure technet --public
attic cache info technet          # prints the public key for attic-cache.nix
```

`--configure-cache-retention` is needed even though nothing here sets a
retention period: `attic cache configure` always sends one, defaulting to the
global value, so every call is checked against that permission as well. Without
it the command fails with a bare "User does not have permission".

The cache is public, meaning any host that can reach the vhost substitutes from
it without a token. That vhost is only reachable over the WireGuard mesh, so
this is the same trust boundary the rest of the network already has, and it
keeps every client's substituter config to a URL and a key with no netrc.

Pushing still needs a token. The mirror service has a long-lived one in
`secrets/2-server/attic.yaml`:

```sh
atticd-atticadm make-token --sub heimdall-mirror --validity '10y' \
    --push 'technet' --pull 'technet'
```

The store itself lives on the data pool via
`environment.persistence."/Storage/Services/Attic"`, and carries a `.nobackup`
marker so borgmatic skips it — the contents are reproducible and would otherwise
dominate the repo. The persisted path is `/var/lib/private/atticd`, not
`/var/lib/atticd`: atticd runs under `DynamicUser`, so systemd owns the private
path and leaves the shorter one as a symlink. Binding over `/var/lib/atticd`
makes systemd try to migrate a mountpoint and the unit dies with `EBUSY`.

## Mirroring the PinePhone kernel

megi's kernel is not on `cache.nixos.org` and its flake no longer publishes a
served substituter — it attaches a signed cache to a GitHub release per commit,
because the GitHub Pages it used before answered HTTP 429 once more than a
machine or two pulled from it.

[`pinephone-kernel-mirror.nix`](../nix/2-server/3-services/technet/pinephone-kernel-mirror.nix)
closes that gap: daily, it downloads the release asset for whatever revision the
flake has locked, imports it, and pushes the three kernel outputs into Attic.
The fleet then substitutes the kernel from Heimdall at LAN speed. It only
downloads when the paths are absent from the store, so this is a cost per kernel
bump rather than a daily one.

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
