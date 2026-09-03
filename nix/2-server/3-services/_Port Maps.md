# Port Maps

Ports used by Heimdall's services, grouped by category. Values are taken from
the service definitions under `nix/2-server/3-services/`. Most web UIs listen on
localhost and are reached through nginx (443) via their `*.heimdall.technet`
vhost; the "Port" column is the upstream/service port nginx proxies to.

A few vhosts proxy to another TechNet host over WireGuard rather than to
loopback. Those carry the upstream's `10.100.100.0/24` address in the Notes
column, and their service definition lives in that host's own directory.

## Reverse Proxy

| Service | Port | Notes |
|---------|------|-------|
| Nginx (HTTP)  | 80  | Redirects to HTTPS |
| Nginx (HTTPS) | 443 | Front door for all `*.heimdall.technet` vhosts |

## Monitoring

| Service | Port | Vhost |
|---------|------|-------|
| Homepage     | 9610 | homepage.heimdall.technet |
| Vigil        | 9611 | vigil.heimdall.technet — also serves the agent WebSocket at `/api/agent/ws`, reachable over WireGuard so Odin and Ragnarok's agents can dial in |

## Networking / DNS

| Service | Port | Notes |
|---------|------|-------|
| Pi-hole (web/FTL)        | 9018 | pi-hole.heimdall.technet |
| Unbound (recursive DNS)  | 5335 | 10.100.100.1 / 127.0.0.1 |

## Home Automation

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Home Assistant | 8123 | home-assistant.heimdall.technet |
| Frigate        | 9310 | 127.0.0.1; frigate.heimdall.technet |
| ESPHome        | 6052 | esphome.heimdall.technet |
<!-- | Traccar        | 9280 | traccar.heimdall.technet | (switched off) -->
| Mosquitto MQTT | 1883 | 127.0.0.1; broker |
| Mosquitto (MQTT over TLS) | 8883 | nginx `stream`, proxied to 1883; mqtt.heimdall.technet |
| Mosquitto (websockets) | 9320 | 127.0.0.1; proxied at /mqtt on the vhost below |
| MQTTX Web | — | Static files served by nginx; mqtt-web.heimdall.technet |

## Fun & Media

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Calibre Web  | 8083 | calibre-web.heimdall.technet |
| FreshRSS     | —    | freshrss (php-fpm via nginx) |
| Jackett      | 9117 | jackett.heimdall.technet |
| Openbooks    | 9777 | openbooks.heimdall.technet |
| qBittorrent (Web UI)   | 9050 | qbittorrent.heimdall.technet |
| qBittorrent (torrents) | 6881 | TCP + UDP |
| VLC (telnet)  | 4212 | 127.0.0.1; headless audio control for Home Assistant |

## TechNet

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Attic (binary cache) | 9400 | 127.0.0.1; attic.heimdall.technet |

## Personal Info & Files

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Trilium      | 8080 | trilium.heimdall.technet |
| Radicale     | 5232 | 127.0.0.1; radicale.heimdall.technet |
| Syncthing (Web UI)   | 8384  | syncthing.heimdall.technet |
| Syncthing (transfer) | 22000 | Default sync ports |
| Syncthing on Odin      | 8384 | 10.100.100.2; syncthing-odin.heimdall.technet |
| Syncthing on Ragnarok  | 8384 | syncthing.ragnarok.lan; loopback only, no Heimdall proxy |
| BlockURL     | 9001 | blockurl.heimdall.technet |

## Vigil Reachability Checks

Vigil's `ports` monitor on Heimdall (`heimdall-ports`) probes these endpoints
from Heimdall to confirm the web stack is reachable:

* Nginx (front door) - localhost:443
* Home Assistant - https://home-assistant.heimdall.technet
* Pi-hole - https://pi-hole.heimdall.technet
* Homepage - https://homepage.heimdall.technet
* Jackett - https://jackett.heimdall.technet

Beyond that generic reachability probe, a few services get a dedicated
app-aware Vigil plugin that checks the service is actually doing its job, not
just answering:

* Pi-hole (`heimdall-pihole-dns`) - block rate + gravity age via the FTL API
* qBittorrent (`heimdall-qbittorrent-transfers`) - transfer/connection health via the WebUI API
* Unbound (`heimdall-unbound-resolution`) - live query + SERVFAIL rate via `unbound-control`
* Mosquitto (`heimdall-mosquitto-delivery`) - publish/subscribe round trip on a dedicated `vigil` MQTT user
* Frigate (`heimdall-frigate-cameras`) - per-camera `connection_quality` via the internal (unauthenticated, loopback-only) API
<!-- * Traccar (`heimdall-traccar-devices`) - device staleness via `/api/devices`, using a dedicated read-only account created once by hand (switched off) -->
* FreshRSS (`heimdall-freshrss-feeds`) - per-feed refresh staleness via the Fever API
* Trilium (`heimdall-trilium-activity`) - note write-activity staleness via ETAPI metrics, using a token created once by hand
* Radicale (`heimdall-radicale-webdav`) - live PROPFIND via a dedicated `vigil` htpasswd account
* Syncthing (`heimdall-syncthing-health`) - folder sync state + device connectivity via the REST API
* Calibre Web (`heimdall-calibre-web-library`) - live OPDS feed request via a dedicated account created once by hand
* Openbooks (`heimdall-openbooks-irc`) - IRC bridge connectivity via a brief WebSocket probe
* Blockurl (`heimdall-blockurl-database`) - blocklist database non-emptiness via its own API

A few of these (FreshRSS, Trilium, Calibre Web) authenticate as an
account or token that has no declarative provisioning in the underlying app —
each has a one-time manual setup step documented in its own `.nix` file and a
placeholder sops secret to fill in afterward.
