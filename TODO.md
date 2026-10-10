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

## Keep Pi-hole responsive while Heimdall's data pool is busy

- [ ] Move Pi-hole's state (`/Storage/Services/PiHole`, including `/etc/pihole`) off
      `data-pool-Heimdall`, or otherwise stop its writes waiting behind bulk writes there
      ([`pi-hole.nix`](nix/2-server/3-services/networking/pi-hole.nix))
- [ ] Confirm Thor gets a DHCP lease and Odin resolves `.technet` names during a large Syncthing
      catch-up

On 2026-09-26 Syncthing on Heimdall was pulling 10.5 GB of the Projects folder, and the data pool,
a mirror with the SMR Toshiba MQ04, had I/O pressure near 90% with sync writes waiting 6-7s.
`pihole-FTL` sat in uninterruptible disk wait, so Thor's Wi-Fi associated but never got a lease and
Odin could not resolve names.

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
