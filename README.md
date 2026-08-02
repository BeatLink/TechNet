# TechNet

The TechNet is my personal network of computing devices, all connected via a WireGuard VPN network.

[![Bump flake.lock](https://github.com/BeatLink/TechNet/actions/workflows/main.yml/badge.svg)](https://github.com/BeatLink/TechNet/actions/workflows/main.yml)

## Serial console (Thor / PinePhone)

The PinePhone's 3.5 mm jack doubles as a UART console. **DIP switch 6** under the
back cover selects which: off = serial, on = headphones.

**115200 8N1, no flow control.** Confirmed against a live Tow-Boot boot with the
official Pine64 TRRS console cable (a CH340, `1a86:7523`, enumerating as
`/dev/ttyUSB0`).

```sh
nix-shell -p picocom --run 'picocom -b 115200 /dev/ttyUSB0'
```

`beatlink` is in `dialout`, so no `sudo` is needed.

Only one process may read the port at a time. Two readers — minicom and a second
capture, say — each receive part of the byte stream, which looks exactly like a
wrong baud rate: structured, repeating, but unreadable. If output is garbled,
check for a second reader before touching the baud rate.
