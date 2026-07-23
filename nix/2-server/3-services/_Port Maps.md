# Port Maps

Ports used by Heimdall's services, grouped by category. Values are taken from
the service definitions under `nix/2-server/3-services/`. Most web UIs listen on
localhost and are reached through nginx (443) via their `*.heimdall.technet`
vhost; the "Port" column is the upstream/service port nginx proxies to.

## Reverse Proxy

| Service | Port | Notes |
|---------|------|-------|
| Nginx (HTTP)  | 80  | Redirects to HTTPS |
| Nginx (HTTPS) | 443 | Front door for all `*.heimdall.technet` vhosts |

## Monitoring

| Service | Port | Vhost |
|---------|------|-------|
| Homepage     | 9610 | homepage.heimdall.technet |
| Vigil        | 9611 | vigil.heimdall.technet |

## Networking / DNS

| Service | Port | Notes |
|---------|------|-------|
| Pi-hole (web/FTL)        | 9018 | pi-hole.heimdall.technet |
| Unbound (recursive DNS)  | 5335 | 10.100.100.1 / 127.0.0.1 |
| DDNS Updater             | 9420 | 127.0.0.1; ddns.heimdall.technet |

## Home Automation

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Home Assistant | 8123 | home-assistant.heimdall.technet |
| Frigate        | 9310 | 127.0.0.1; frigate.heimdall.technet |
| ESPHome        | 6052 | esphome.heimdall.technet |
| Traccar        | 9280 | traccar.heimdall.technet |
| Mosquitto MQTT | 1883 | Broker |

## Fun & Media

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Calibre Web  | 8083 | calibre-web.heimdall.technet |
| FreshRSS     | —    | freshrss (php-fpm via nginx) |
| Jackett      | 9117 | jackett.heimdall.technet |
| Openbooks    | 9777 | openbooks.heimdall.technet |
| qBittorrent (Web UI)   | 9050 | qbittorrent.heimdall.technet |
| qBittorrent (torrents) | 6881 | TCP + UDP |
| VLC (telnet)  | 4212 | Headless audio control |

## Personal Info & Files

| Service | Port | Vhost / Notes |
|---------|------|---------------|
| Trilium      | 8080 | trilium.heimdall.technet |
| Radicale     | 5232 | 127.0.0.1; radicale.heimdall.technet |
| Syncthing (Web UI)   | 8384  | syncthing.heimdall.technet |
| Syncthing (transfer) | 22000 | Default sync ports |
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
