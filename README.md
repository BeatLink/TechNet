# TechNet

The TechNet is my personal network of computing devices, all connected via a WireGuard VPN network.

[![Bump flake.lock](https://github.com/BeatLink/TechNet/actions/workflows/main.yml/badge.svg)](https://github.com/BeatLink/TechNet/actions/workflows/main.yml)

## Index

### Hardware

* [1. Backup Server](docs/Hardware/1.%20Backup%20Server/README.md)
* [2. Server](docs/Hardware/2.%20Server/README.md)

### Loki

Loki is my smart watch and biometric monitor. It a PineTime watch running wasp-os

### Tech Kit

I also maintain a tech kit containing computer repair tools and useful peripherals and accessories.

## Architecture

### Filesystem

All devices in the TechNet are configured with dedicated, encrypted ZFS root drives following the Erase Your Darlings paradigm with the impermanence module used for linking state. Additionally, all devices in the TechNet are configured with dedicated encrypted ZFS data drives for persisting state

### Network

All devices in the TechNet are linked by a WireGuard VPN that is not routable by the public internet

| Host                    | Local IP Address    | Wireguard       |
| ----------------------- | ------------------- | --------------- |
| IP Subnet               | 192.168.0.0/24      | 10.100.100.0/24 |
| Heimdall                | 192.168.0.2         | 10.100.100.1    |
| Odin                    | 192.168.0.3         | 10.100.100.2    |
| Hela                    | 192.168.0.4         | 10.100.100.3    |
| Thor                    | 192.168.0.5         | 10.100.100.4    |
| Ragnarok                | DHCP (Family Wi-Fi) | 10.100.100.6    |
| Light - Bedroom         | 192.168.0.10        | 10.100.100.10   |
| Light - Kitchen         | 192.168.0.11        | 10.100.100.11   |
| Light - Bathroom        | 192.168.0.12        | 10.100.100.12   |
| Light - Bedroom Desk    | 192.168.0.13        | 10.100.100.13   |
| Light - Outside         | 192.168.0.14        | 10.100.100.14   |
| Light - Spare Bulb      | 192.168.0.15        | 10.100.100.15   |
| IR - Fan                | 192.168.0.16        | 10.100.100.16   |
| Socket - Fan            | 192.168.0.17        | 10.100.100.17   |
| Socket - Ragnarok       | DHCP (Family Wi-Fi) | 10.100.100.18   |
| Sensor - Bathroom Light | 192.168.0.19        | 10.100.100.19   |
| Sensor - Bedroom        | 192.168.0.20        | 10.100.100.20   |
