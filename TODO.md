# To Do

## Subscribe the phone to Vigil's alerts

- [ ] Install the ntfy app on the phone, with the phone connected to TechNet
- [ ] Add the server `https://ntfy.heimdall.technet`, trusting TechNet's HTTPS certificate if the app asks
- [ ] Sign in as `beatlink`, with the password from
      `sops decrypt --extract '["beatlink_password"]' secrets/2-server/ntfy.yaml`
- [ ] Subscribe to the topic `vigil`, then send a test from the bell icon in Vigil's dashboard

Vigil publishes its alerts to ntfy on Heimdall (`nix/2-server/3-services/monitoring/ntfy.nix`); until the
phone subscribes, nothing reads them.

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
