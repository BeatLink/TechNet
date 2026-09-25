# To Do

## Confirm Ragnarok's Vorta rewrite finishes

- [ ] Confirm the `borg recreate` from Odin against `ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Vorta`
      finished and the `borg compact` after it ran
- [ ] Confirm the lock is gone from `/Storage/Backups/Laptop/Vorta` on Ragnarok
- [ ] Confirm Vorta's next "3. Ragnarok Backup" run succeeds

The rewrite is `ragnarok-run.sh` from `/Storage/Files/Backups/Laptop/vorta-purge-2026-09-24/`, which
was 31 of 77 archives in at 23:43 on 2026-09-24. Its log is
`~/.claude/tmp/claude-1000/-Storage-Files-Projects-TechNet/18ceb386-f731-4c6c-8afa-e85f87c1f9ce/scratchpad/purge-ragnarok.log`,
in a directory that had been deleted and was recreated by hand. A missing log directory
makes bash skip any command redirected into it, so check the log ends with `compact exit 0` and
`DONE`. If the compact did not run, run `borg compact` on that repository by hand.

## Deploy the Vigil borg monitor extras

- [ ] Deploy Heimdall and Odin, so they get commit `ff6c7f04` and Vigil `ee51de2` or later
- [ ] Expect the restore checks to fail until the next scheduled backup includes each canary file,
      then confirm every borg monitor's RESTORE CHECK card shows Passed
- [ ] Decide whether Vorta's "2. Heimdall Backup" profile is right to keep no weekly or monthly
      archives; `vigil.nix` was changed to match it, so if Vorta is wrong, fix the profile and put
      back `keep_weekly = 2` and `keep_monthly = 3` on the `backup-laptop-heimdall` monitor

The canary files are `/Storage/Services/.vigil-canary` on Heimdall, and `/Storage/System/.vigil-canary`
and `/Storage/Files/.vigil-canary` on Odin. Heimdall's "Ragnarok" backup monitor stays failed until the
repair below is done.

## Repair the missing chunk in Ragnarok's server repository

- [ ] Run the repair below on Ragnarok
- [ ] Confirm Heimdall's next `borgmatic-check.service` run finishes successfully
- [ ] Delete `/Storage/Backups/Server/Borgmatic.pre-repair-20260924` on Ragnarok

Heimdall's `borgmatic-check.service` has failed on every run since at least 2026-09-22, because of
one fault in Ragnarok's copy of the server repository (`ssh://borg@ragnarok.technet/Storage/Backups/Server/Borgmatic`).
The failing run on 2026-09-24 reported:

- The repository and data checks were clean: no segment problems, and all 181,966 chunks verified.
- The archive check found one missing file chunk in archive `backup-2026-08-20T01:53:42`, in
  `Storage/Services/Home-Assistant/config/backups/Automatic_backup_2026.8.1_2026-08-17_05.08_39003985.tar`
  (bytes 146325898–147981586).

Heimdall's local copy (`/Storage/Files/Backups/Server/Borgmatic`) passed the same checks and is not
affected.

Run this on Ragnarok as the `borg` user, so the repository files stay owned by `borg`:

```sh
R=/Storage/Backups/Server/Borgmatic
sudo -u borg env BORG_PASSCOMMAND="cat /run/secrets/borg_repo_encryption_key" BORG_BASE_DIR=/var/lib/borg-check \
  BORG_RELOCATED_REPO_ACCESS_IS_OK=yes BORG_CHECK_I_KNOW_WHAT_I_AM_DOING=YES sh -c "
  borg with-lock --lock-wait 3600 $R cp -a --reflink=always $R $R.pre-repair-20260924 &&
  borg check --repair --archives-only --lock-wait 3600 --info $R"
```

The first step takes an instant copy of the repository on btrfs while holding borg's lock, so the
repair can be rolled back. The second step repairs only the archive metadata, because the
repository check was clean. The repair fills the missing chunk with zeros, so that one tar in that
one archive stays damaged. Once the Vigil borg monitors are deployed, the "Ragnarok" backup monitor
under Heimdall's Backups group shows the check result.

## Fix keyboard-dock-rotation failing during a switch

- [ ] Make `keyboard-dock-rotation` survive a moment with no logical monitor, instead of crashing
- [ ] Confirm it is active again on Thor after the next deploy

Thor's `keyboard-dock-rotation` user service
([`dock-rotation.nix`](nix/5-phone/1-system/dock-rotation.nix)) failed at 2026-09-24 23:23:22,
when home-manager started it during the nixos-upgrade switch. `monitor_state()` read an empty
logical-monitor list from Mutter's display config and raised `IndexError` at `logical[0][2]`, so
the panel no longer turns to landscape when the case docks until the service is started again.

## Move a database off Heimdall's data pool

- [ ] Decide whether atticd's state directory or Vigil's `vigil.db` moves to `root-pool-Heimdall`
- [ ] Confirm the Attic cache answers in well under a second afterwards

`atticd` keeps its SQLite in its state directory on `data-pool-Heimdall`
([`attic.nix`](nix/2-server/3-services/technet/attic.nix)), the `MQ04ABF100` SMR mirror, and
`/Storage` on the same pool holds Vigil's `vigil.db`, 3.58GB and written continuously. A plain
`nix-cache-info` request takes 10-30 seconds, every host's substitutions fall back to building with
HTTP 500s, and a 400MB `attic push` cannot finish at all: atticd's connection pool times out and
returns 500 after 45s. Frigate is not involved -- it starts disarmed and was recording nothing.
`root-pool-Heimdall` is a 64GB SSD with 25GB free, so only one of the two databases fits there.

## Push the Packet Tracer deb into Attic

- [ ] Retry `attic push technet /nix/store/<hash>-CiscoPacketTracer_901_Ubuntu_64bit.deb` once the
      cache is quiet, or once a database has moved off the data pool

Odin and Heimdall both hold the path with a GC root, so nothing is blocked today; a host that has
never had the file is the case this covers. Three attempts on 2026-09-24 timed out, including one
with both `attic-watch-store` units stopped and no build running.

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
