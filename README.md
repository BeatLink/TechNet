# TechNet

The TechNet is my personal network of computing devices, all connected via a WireGuard VPN network.

[![Bump flake.lock](https://github.com/BeatLink/TechNet/actions/workflows/main.yml/badge.svg)](https://github.com/BeatLink/TechNet/actions/workflows/main.yml)

## Index

### Ragnarok

Ragnarok is the backup server for the TechNet. It is setup at my family's home as an offsite backup. It is powered by a Rock64 Single Board Computer

### Heimdall

Heimdall is my home server and acts as the hub of the TechNet. It is powered by a headless Acer Laptop

### Odin

Odin is my laptop and primary workstation. It is a Lenovo Ideapad Gaming 3

### Hela

Hela is my tablet and is used mainly for media consumption, viewing recipes and controlling HomeAssistant. It is a Samsung Galaxy A8

### Thor

Thor is my smartphone and mobile command center. It is mainly used for communications and computing while mobile.

### Loki

Loki is my smart watch and biometric monitor. It a PineTime watch running wasp-os

### Tech Kit

I also maintain a tech kit containing computer repair tools and useful peripherals and accessories.

## Architecture

### Filesystem

All devices in the TechNet are configured with dedicated, encrypted ZFS root drives following the Erase Your Darlings paradigm with the impermanence module used for linking state. Additionally, all devices in the TechNet are configured with dedicated encrypted ZFS data drives for persisting state

### Network

All devices in the TechNet are linked by a WireGuard VPN that is not routable by the public internet

* IP Subnet:    10.100.100.0/24
* Heimdall:     10.100.100.1
* Odin:         10.100.100.2
* Hela:         10.100.100.3
* Thor:         10.100.100.4
* Ragnarok:     10.100.100.5
* Socket Ragnarok: 10.100.100.10

## Apps

### Comms

#### Contacts

Contacts are managed by the Radicale server on Heimdall. DavX5 is used to sync them with the contacts and phone apps on Thor. They are managed on Odin using Thunderbird.

#### SMS

SMS are managed on Android using the messaging app. Valent can be used to connect to Thor to send SMS messages.

#### WhatsApp

WhatsApp is used to connect with friends and family. The main app is installed on Thor and the web app is used on Odin. Desktop files are created to access WhatsApp Web from plank reloaded.

### Core
