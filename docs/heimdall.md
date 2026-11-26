# Heimdall — server

| | |
| --- | --- |
| Device | Lenovo ThinkCentre M710q Tiny, Intel Core i3-7100T |
| Platform | `x86_64-linux` |
| Modules | [`nix/0-common`](../nix/0-common) + [`nix/2-server`](../nix/2-server) |
| Address | `heimdall.technet`, `10.100.100.1` over WireGuard, `192.168.0.2` on the LAN |

Heimdall is the always-on server and the hub of the network. It terminates the
WireGuard tunnel that every other host dials into, serves DNS, and runs the
services in [`3-services`](../nix/2-server/3-services).

## Hardware

Heimdall moved from an Acer Aspire E5-575 to the M710q on 2026-11-20. It has
32 GB of RAM and two drives:

| Use | Drive | Connection |
| --- | --- | --- |
| Root pool, `root-pool-Heimdall` | Samsung PM991 256 GB NVMe SSD | Internal M.2 slot |
| Data pool, `data-pool-Heimdall` | ADATA SU720 1 TB 2.5" SATA SSD | Internal 2.5" bay |

The root drive was a 64 GB M.2 SATA SSD in a USB enclosure until the NVMe drive
replaced it, as the M.2 slot takes NVMe only.
[`hardware.nix`](../nix/2-server/1-system/hardware.nix) still loads `usb_storage`
and `uas` in the initrd so the root drive can boot from an enclosure again.

The data pool was a mirror of the ADATA SSD and a Toshiba MQ04ABF100 hard disk.
The M710q has one 2.5" bay, so the hard disk was detached and the pool is now a
single drive with no redundancy; the backups are its only second copy.

| Interface | Device | Driver | MAC | Address |
| --- | --- | --- | --- | --- |
| `lan0` | Intel I219-V Ethernet | `e1000e` | `00:23:24:df:00:10` | `192.168.0.2`, static |
| `wlp2s0` | Intel Wireless-AC 8265 | `iwlwifi` | `5c:87:9c:15:09:3c` | DHCP, fallback only |

Both are the permanent addresses the kernel reads from the cards. The machine
is also recorded with the MAC `6C:4B:90:AD:5F:36`, which neither interface
reports; a DHCP reservation made for it matches nothing, and `lan0` does not
need one because its address is static.

[`networking.nix`](../nix/2-server/1-system/networking.nix) renames the wired
NIC to `lan0` by type, not by PCI slot, so the address and the firewall rules
follow it onto other hardware. Both `e1000e` and `r8169` are in the initrd.
[`wifi.nix`](../nix/2-server/1-system/wifi.nix) joins the fleet's known Wi-Fi
networks once the system has booted, with a higher route metric than `lan0`, so
Wi-Fi only carries traffic when the wired link is down. It does not run in the
initrd.

### Failover to the Thor hotspot

When the home internet goes down, both `lan0` and the home Wi-Fi go through the
same dead router, so the `wifi-failover` service in `wifi.nix` moves Heimdall's
own traffic onto the hotspot ThorX broadcasts as `Thor`:

1. Every minute it pings 1.1.1.1, 8.8.8.8 and 9.9.9.9. Once none has answered
   for 5 minutes, it tells wpa_supplicant to join `Thor`.
2. networkd matches that SSID with `02-wifi-thor`, whose default route has
   metric 100, below `lan0`'s 1024, so the hotspot carries the traffic.
3. Every 2 minutes it pings the same hosts through `lan0` only. Once one
   answers, it reloads wpa_supplicant's config, which rejoins the home
   networks and leaves `Thor` disabled again.

`Thor` is disabled in wpa_supplicant's config, so Heimdall never joins it on
its own. The hotspot has to be switched on by hand on ThorX. Stopping the
service also rejoins the home networks. Follow it with
`journalctl -u wifi-failover`.

Only Heimdall's own traffic fails over. WireGuard peers dial the home
connection's address, so remote access stays down until it returns.

## Bluetooth

[`bluetooth.nix`](../nix/2-server/1-system/bluetooth.nix) turns on the 8265's
Bluetooth radio (`hci0`, USB `8087:0a2b`) for Home Assistant.
[`presence.nix`](../nix/2-server/3-services/home-automation/home-assistant/presence.nix)
adds two presence entities:

| Entity | How it is detected | Limit |
| --- | --- | --- |
| `binary_sensor.thor_nearby` | `l2ping` to Thor's address every minute | Thor starts with Bluetooth off, so it only shows while switched on |
| `device_tracker.pinetime` | The watch's BLE advertisement, through `bluetooth_le_tracker` | The watch stops advertising while a phone is connected to it |

Tracked BLE devices are declared in `knownDevices` in the Home Assistant
module, which links them in as a read-only `known_devices.yaml`.

On its first boot here the hardware clock read 2019-12-17, almost seven years
behind, and units that need a valid date early, such as `unbound-root-hints`,
failed. NTP corrected the system time and the kernel wrote it back to the
hardware clock. If the wrong date returns after the machine has been unplugged,
the CMOS battery is flat and needs replacing.

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
| `communication` | mail (dovecot, imapsync, roundcube), matrix (synapse, mautrix bridges) |
| `personal-info-and-files` | blockurl, radicale, syncthing, trilium |
| `fun-and-media` | calibre-web-automated, comet, freshrss, jackett, qbittorrent, stremio, vlc |
| `home-automation` | esphome, frigate, home-assistant, lnxlink, mosquitto |
| `monitoring` | homepage, x-monitor |
| `technet` | attic, atuin, atuin-web |
| `backups` | borg, borgmatic |

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

## Matrix

Heimdall runs a private [Matrix](../nix/2-server/3-services/communication/matrix.nix)
homeserver, Synapse, at `https://matrix.heimdall.technet/`. Federation is off, so
it is reachable only over WireGuard and talks to no other Matrix server. Bridges
bring WhatsApp and Discord chats into it as ordinary rooms, so one Matrix
client covers both. Synapse keeps its data
in the shared Postgres instance; the bridges keep theirs under
`/Storage/Services/Matrix`.

The account's username and password are `matrix_username` and `matrix_password`
in `secrets/2-server/matrix.yaml`, which ships with `CHANGEME` placeholders
(edit it with `sops secrets/2-server/matrix.yaml`). On each switch,
`matrix-synapse-account` creates the account if it is missing and leaves an
existing one alone; it sits in `failed` until the placeholders are replaced.
Later password changes are made from the client. Sign in from Element (or any
Matrix client) with homeserver `https://matrix.heimdall.technet`.

Each bridge is linked by messaging its bot from that account and sending `login`:

| Network | Bot | Login |
| --- | --- | --- |
| WhatsApp | `@whatsappbot:matrix.heimdall.technet` | QR code, scanned from WhatsApp > Linked devices |
| Discord | `@discordbot:matrix.heimdall.technet` | `login-qr` instead of `login`, scanned from the Discord mobile app |

The Discord bridge signs in as the user account, which Discord's terms forbid.

Double puppeting is on for every bridge: messages sent from the phone apps show
in Matrix as sent by the Matrix account itself, not by a bridge ghost, and reads
sync both ways. It runs through a `doublepuppet` app service whose token
`matrix-double-puppet` makes on first start under `/var/lib/matrix-synapse`;
nothing about it is in the repository or in sops.

### Keeping the linked accounts safe

Each bridge is one more logged-in device, so it draws the least attention when
it behaves like the official apps:

- Link each account from home, so the bridge's address is one the account
  already uses.
- Link each network once and leave it linked; repeated logins trip account checks.
- Bridge Discord servers one at a time with `guilds bridge <id>`, only the ones
  actually read.
- Send at a human pace: no scripts, bots or mass invites through bridged accounts.
- History stays shallow: WhatsApp takes what the phone hands any new linked
  device, Discord none.

## Mail

[`mail`](../nix/2-server/3-services/communication/mail) moves mail off Gmail and
Outlook.com into a Dovecot mailbox on Heimdall. Every 10 minutes imapsync copies
each account's folders into a top-level `Gmail` or `Outlook` folder of that
mailbox. Inside each, the main folders are numbered `1. Inbox`, `2. Drafts`,
`3. Sent` and `4. Archive`, so every mail client lists them first and in that
order. Read it from any IMAP client at `mail.heimdall.technet`, port 993 with
SSL/TLS, or in a browser at `https://mail.heimdall.technet/` (Roundcube), on
the LAN or over WireGuard; both sign in with `mail_username` and `mail_password`.
Sending still goes through each account's own SMTP server. The mail sits as Maildir files under `/Storage/Services/Mail`,
which the `/Storage/Services` backups cover.

`secrets/2-server/mail.yaml` ships with `CHANGEME` placeholders, and every mail
unit sits in `failed` until they are replaced (`sops secrets/2-server/mail.yaml`):

| Key | Value |
| --- | --- |
| `mail_username`, `mail_password` | The login mail clients use on Heimdall |
| `gmail_address`, `gmail_app_password` | An app password from Google Account > Security > App passwords, which needs 2-Step Verification |
| `outlook_address` | The Outlook.com address |

### Gmail

Each label shows up as its own folder, so a message with two labels is copied
twice. `[Gmail]/All Mail` goes last and lands in `Gmail/4. Archive`, holding only
archived mail with no label. Before deletion is switched on, set Gmail's
Settings > Forwarding and POP/IMAP to auto-expunge and to *Immediately delete
the message forever*, and untick *Show in IMAP* for Important and Starred;
otherwise a deleted message only loses its label and stays in Gmail.

### Outlook

Outlook.com accepts only OAuth for IMAP, and personal accounts cannot register
an OAuth app of their own. The sign-in needs a client ID from either an app
registered in a free Entra ID tenant (multi-tenant with personal accounts,
public client, redirect `http://localhost`) or a published open-source mail
client's public ID. Sign in once on Heimdall, then open the printed address in
any browser and paste back the address it lands on:

```sh
sudo -u vmail mail-oauth init /Storage/Services/Mail/oauth/outlook.json \
    --client-id <client id> --redirect-uri http://localhost
```

Each run refreshes the token, so the sign-in lasts as long as it is used at
least every 90 days. Run `init` again if `mail-fetch-outlook` reports
`invalid_grant`.

### Moving the mail off

`delete_from_source` in the module is on, so each run deletes what it copied
from the account and Heimdall holds the only copy, covered by the
`/Storage/Services` backups. Set it to `false` to go back to copying only.
Outlook keeps deleted mail in Recoverable Items for a while; empty it by hand
to clear it from Microsoft's servers sooner.

## Shell history

Heimdall runs [Atuin](../nix/2-server/3-services/technet/atuin.nix) at
`https://atuin.heimdall.technet/` as the fleet's shell history store. Every host
records `beatlink` and `root` shell commands into it end-to-end encrypted, so
Ctrl-R on any host searches the whole fleet's history. Plain `HISTFILE` is left
in place alongside it and still backs the up-arrow. Its Postgres instance, which
Comet shares, keeps its data on the data pool at `/Storage/Services/PostgreSQL/16`.

Registration is not declarative, and the server refuses it by default. Open it
for one call, register, then take the override away:

```sh
# On Heimdall.
sudo mkdir -p /run/systemd/system/atuin.service.d
printf '[Service]\nEnvironment=ATUIN_OPEN_REGISTRATION=true\n' \
    | sudo tee /run/systemd/system/atuin.service.d/register.conf
sudo systemctl daemon-reload && sudo systemctl restart atuin
atuin register -u beatlink -e <email> -p <password>
atuin key                         # prints the encryption key
sudo rm -r /run/systemd/system/atuin.service.d
sudo systemctl daemon-reload && sudo systemctl restart atuin
```

The password and key then go into `secrets/0-common/atuin.yaml`, which ships
with `CHANGEME` placeholders:

```sh
sops secrets/0-common/atuin.yaml
```

`atuin-login-beatlink` and `atuin-login-root` read that file on every host and
log in once per install, skipping the call when `atuin status` already reports a
login. Until the placeholders are replaced both units sit in `failed` and retry
every minute.

A host's pre-existing `HISTFILE` is folded in once, per host and per user:

```sh
atuin import bash                 # reads $HISTFILE
atuin sync
```

Bash writes no timestamps here, so the imported commands are spread over
synthetic times before the import; searching is unaffected.

## Shell history in a browser

[atuin-web](../nix/2-server/3-services/technet/atuin-web.nix) serves the same
history at `https://atuin-web.heimdall.technet/`. It is read-only and keeps no
account of its own — it proxies to the atuin server on loopback, and a visitor
signs in with the same credentials the hosts use.

The package comes from a fork pinned in `flake.nix`, carrying two changes still
in review upstream: the Nix packaging
([josegonzalez/atuin-web#81](https://github.com/josegonzalez/atuin-web/pull/81))
and a fix for the records page showing only one host's records
([#82](https://github.com/josegonzalez/atuin-web/pull/82)). Repoint the input at
`github:josegonzalez/atuin-web` once both merge.

Records are decrypted in the browser, never on the server, so the history reads
as PASETO ciphertext until the atuin encryption key from
`secrets/0-common/atuin.yaml` is entered in the UI. It is held in `sessionStorage`
and never sent to the server.

Setting `ATUIN_WEB_TOKEN` through the module's `environmentFile` would drop the
login prompt and show the history to anyone who can reach the vhost; it is
deliberately left unset.

## Stremio addon

[Comet](../nix/2-server/3-services/fun-and-media/comet.nix) serves a Stremio
addon at `https://comet.heimdall.technet/configure`. It searches the local
Jackett and the public Torrentio instance when a title is opened and hands
Stremio the deduplicated torrents directly, so no debrid account is needed; the [streaming server](#stremio) plays them. Jackett's
API key is read from its `ServerConfig.json` each time the service starts, and
Comet's cache lives in a `comet` database on the Postgres instance atuin also
uses.

The package comes from a fork pinned in `flake.nix`, because the Nix packaging
is not upstream yet. Repoint the input at `github:g0ldyy/comet` once it merges.

## Stremio

[`stremio.nix`](../nix/2-server/3-services/fun-and-media/stremio.nix) runs
Stremio as two pieces on two vhosts:

* `https://stremio.heimdall.technet` — the web UI, built from source by
  [`stremio-web.nix`](../nix/2-server/3-services/fun-and-media/stremio-web.nix)
  and served straight off disk by nginx.
* `https://stremio-server.heimdall.technet` — the streaming server, the Node
  blob that turns a torrent into a playable HTTP stream and transcodes it with
  jellyfin-ffmpeg.

They need separate names. The UI resolves every call against the *root* of
whatever streaming server URL it is given, so hanging the server off a path on
the UI's own name would drop that path and 404.

The UI is built from source for two reasons, both of which the published
release zip gets wrong for this network.

The first is the streaming server address. Upstream's default is
`http://127.0.0.1:11470/` — the *viewer's* machine, which runs nothing, so an
unaimed UI reports the server as unavailable. The build patches
`src/common/CONSTANTS.js` so the UI's own default is this network's server.
That alone is not enough: the profile the wasm core starts from still carries
the loopback address, so the UI must still be handed
`?streamingServerUrl=` in the query string. What the patch buys is that the
URL it is handed now matches its own default, which `SearchParamsHandler`
adopts silently instead of raising a confirmation modal. Two redirects deliver
it:

* the server's root redirects to the UI with the parameter filled in;
* the UI's own root redirects to itself with the parameter when it is missing.

nginx issues both redirects rather than the streaming server, which derives
the protocol from its own socket and would therefore offer an `http://` URL the
HTTPS UI refuses as mixed content.

The second reason is the service worker. Workbox precaches `index.html` and
maps a bare `/` onto it, so a browser that had loaded the UI once was served
that cached page forever and never saw either redirect — which is exactly how
this failed in practice. The build sets `SERVICE_WORKER_DISABLED`, which makes
`useServiceWorkerUpdater` return before registering anything, and the
registration is then dropped from the bundle as dead code. Browsers that
already registered the old worker are not fixed by that, so nginx also serves
a replacement `service-worker.js` that unregisters itself and empties the
caches.

Three environment variables matter. `NO_CORS` is required — without it the
server sends CORS headers only to `strem.io` origins and the UI gets none.
`NO_HTTPS_SERVER` stops it opening port 12470 and fetching a certificate for it
from `api.strem.io`, since nginx owns TLS here. `CASTING_DISABLED` stops it
scanning the network for receivers nothing will use.

The cache lives at `/Storage/Services/Stremio-Server` behind a `.nobackup`
marker: it is re-downloadable stream data and would otherwise dominate the borg
repo. The persisted path is `/var/lib/private/stremio-server`, not
`/var/lib/stremio-server`, for the same `DynamicUser` reason as Attic above.

The server's listening port is not configurable — `server.js` hardcodes 11470
and only walks up to 11474 if that is taken. `PORT` is read by the bundled
addon SDK and does not move this listener.

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
bump rather than a daily one. A commit that has no release of its own, such as
one made while the kernel repository's CI was not running, falls back to the
newest release, which only succeeds if that release holds the exact same paths.
The timer keeps a fixed random delay, so a switch's reload cannot fire it
mid-switch.

## Unlocking

Heimdall's root pool is unlocked by clevis against Odin's tang server, enabled in
[`clevis.nix`](../nix/2-server/1-system/clevis.nix). The passphrase is stored
as `heimdall_encryption_key` in `secrets/admin/nixtool.yaml`, readable only with
your own age key; `rebind-clevis Heimdall` on Odin renews the bindings from it.

Because tang runs on Odin and stops when Odin's session locks, **Heimdall will
not come back from a reboot unless Odin is awake and unlocked**. The
`clevis-retry` service keeps trying in the background rather than blocking the
boot, so it will unlock on its own once tang appears.

Initrd WireGuard plus initrd SSH mean a stuck boot can be fixed remotely, which
is the reason that combination exists.

With no network and no display there is a third way in, from
[`serial-console.nix`](../nix/2-server/1-system/serial-console.nix): a USB
serial adapter plugged into Heimdall as `ttyUSB0` answers the boot password
prompts in the initrd and carries a login prompt once booted, at 115200 baud.
Wire it to a second adapter on another machine with TX to RX, RX to TX and
ground to ground. This path has not been tested on the hardware yet.

## Rebuilding

```sh
nixtool run maintenance/rebuild --host Heimdall --action dry-activate
nixtool run maintenance/rebuild --host Heimdall --action switch
```

Restarting a service group tends to be more disruptive here than on other hosts —
read the unit list from `dry-activate` before switching.
