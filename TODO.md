# To Do

## Finish the move from Vigil to X-Monitor

- [ ] Update browser bookmarks from `vigil.heimdall.technet` and `x-monitor.heimdall.technet` to `monitor.heimdall.technet`; links in notifications sent before the switch stop working

Left named Vigil on purpose, because renaming them needs a hand-made change in a running service or an encrypted file:
Trilium's ETAPI token named Vigil; the sops key names (`*_vigil_*`, `vigil_*`) and
`HOMEPAGE_VAR_VIGIL_PASS` inside `homepage_env`; the `.vigil-canary` files, whose archived copies the restore checks compare;
the `vigil-self` monitor id and the Home Assistant automation and webhook ids, which key existing history.

## Finish dropping x- from the app domains

- [ ] Point the X-Tasks desktop and Android apps' sync server at `tasks.heimdall.technet`; `x-tasks.heimdall.technet` no longer resolves

## Confirm Odin's Ragnarok repository passes its monthly checks

- [ ] Confirm X-Backups' extract check of `odin-ragnarok` on 2026-12-04 succeeds
- [ ] Confirm its data check on 2026-12-11 succeeds

Both last failed while the Vorta replay held that repository: the extract check on 2026-11-04 exited 2, and the
data check on 2026-11-11 timed out on the lock of its repository. Its weekly check has passed.

## Finish moving the fleet to X-Backups

- [ ] Remove X-Monitor's borg plugin from its TypeScript port (`src/monitors/borg/`) once that port lands; X-Monitor only
      checks X-Backups' health now

## Confirm the November fixes held

- [ ] Confirm X-Nix's nightly build on Odin finishes under its new 40% memory cap
      ([`memory-guard.nix`](nix/3-laptop/1-system/memory-guard.nix)), and raise the cap if the build dies at it
- [ ] Confirm Tow-Boot no longer starts netconsole after Ragnarok's next reboot

On 2026-11-13 Odin's agent peaked at 3.1 GB of its 11.7 GB cap with no OOM, but it logged nothing to show a build ran.

## Install LNXlink on Ragnarok and Thor

- [ ] Add LNXlink to Ragnarok, as a system service like Heimdall's
      ([`lnxlink.nix`](nix/2-server/3-services/home-automation/lnxlink.nix))
- [ ] Add LNXlink to Thor, as a user service like Odin's
      ([`lnxlink.nix`](nix/3-laptop/4-apps/technet/lnxlink.nix))
- [ ] Give each host its own broker account in Heimdall's
      [`broker.nix`](nix/2-server/3-services/home-automation/mosquitto/broker.nix)
- [ ] Confirm both show up in Home Assistant through MQTT discovery

## Features System Bridge has that LNXlink lacks

From a feature comparison of the two in August 2026. Nothing here is needed yet; it is the list to
check before deciding LNXlink covers everything.

- [ ] Windows support; LNXlink runs on Linux only
- [ ] A native Home Assistant integration over its own API and WebSocket, with no MQTT broker
- [ ] A built-in MCP server, so an AI assistant can query and control the machine
- [ ] An Android companion app
- [ ] A tray app, a web client and a settings UI
- [ ] Display sensors: resolution and refresh rate of each monitor
- [ ] Looking up running processes by PID or name
- [ ] Power usage as a wattage sensor, for the whole system and the GPU
- [ ] GPU clock, fan speed, temperature and power sensors
- [ ] Hibernate, lock and log out as power actions
- [ ] Notifications with action buttons, images and sound
- [ ] Browsing media sources, not just controlling playback

## Find why Thor's ActivityWatch device id keeps changing

- [ ] Find why Thor's aw-server lost its device id twice, and fix what loses it
- [ ] Confirm the two deleted export folders do not come back from Thor's local sync folder

Thor exported under three device ids: `0e0fb438` on 2026-09-26, `34e53ad4` on 2026-09-29 and
`1ddd78b2` on 2026-10-03. Each one is a fresh aw-server identity, so the persisted
`~/.local/share/activitywatch` (backed by `/Storage/Apps/TechNet/ActivityWatch`) is not surviving
something, whether a reboot or a reinstall. The first two exports were deleted from
`/Storage/Files/ActivityWatch` on 2026-10-04, after confirming Heimdall already holds their events.
Thor's sync job copies everything in `~/.local/share/activitywatch/sync` to Heimdall, so if either
folder is still there, it will reappear in the share.

## Check why ThorX's ActivityWatch app stopped syncing

- [ ] Open the app's Sync Settings on ThorX and check its last and next sync times
- [ ] Confirm a newer export reaches `/Storage/Files/ActivityWatch` and shows up on Heimdall

The Android app exported once: its folder in the share last changed on 2026-09-29, and its newest
event is from 2026-09-30. It writes one level deeper than the other hosts, under a folder named
after the device, which Heimdall's import reads through a second pull.

## Stop aw-sync duplicating Thor's AFK events on Heimdall

- [ ] Find why each pull re-adds copies of Thor's AFK events, and fix it or report it upstream
- [ ] Until then, remove the copies now and then by grouping each `-synced-from-` bucket's events on
      timestamp, duration and data and deleting all but one through aw-server's API

On 2026-10-04 Heimdall's `aw-watcher-afk_Thor-synced-from-Thor` held 5,902 events of which 24 were
distinct, and Odin's AFK and Firefox buckets held smaller numbers of exact copies. After every copy
was deleted, two 5-minute pulls added 12 more to Thor's AFK bucket alone, from a single export that
was not changing because Thor was offline. Every other bucket stayed clean over those two pulls.

## Give BattleTime Companion the computer's location on Odin

- [ ] Check whether Cinnamon runs a GeoClue agent for beatlink; GeoClue never answers `GetClient`
      for a user without one
- [ ] Enable `services.geoclue2` on Odin with an `appConfig` entry for `battletime-companion`, the
      DesktopId the app asks under
- [ ] Turn on "Use where this computer is" in the app's Settings and confirm it finds a place

Until then the app's weather uses a place chosen by name, which already works.

## Flash the Ragnarok socket with its .technet name

- [ ] Once `socket-ragnarok` is back online, flash it from Heimdall with Device Builder's own ESPHome
      CLI (`esphome run socket-ragnarok.yaml --device socket-ragnarok.technet`, as the `esphome` user)
- [ ] Confirm X-Monitor's "Ragnarok Socket" monitor and the "IoT Sensors" group it belongs to show online

It is the only device not flashed since `.lan` was folded into `.technet`. Home Assistant and X-Monitor
already reach it as `socket-ragnarok.technet` over WireGuard (`10.100.100.18`), so the flash only
updates the name the firmware reports. Until it is online, X-Monitor's "IoT Sensors" group stays failed.
