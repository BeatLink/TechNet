# To Do

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
