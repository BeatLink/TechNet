# Backups — borg traps

Which host backs up what is in the [backup map](backup-map.html); Ragnarok's side is in
[Ragnarok](ragnarok.md#backups).

- **Locks.** A `check --verify-data` of a Ragnarok repository runs for hours and holds the repo lock throughout, and
  under X-Backups it also holds the client host's `/run/x-backups-borg.lock`, so that host's other jobs queue.
  `Failed to create/acquire the lock` during that time is the check, not a stale lock: look for a running check
  before any `borg break-lock`.
- **Cache lock.** `--bypass-lock` skips the repo lock, but borg still locks its local chunks cache. Two calls with
  the same `cache_dir` serialise on it, and the loser times out. A lock path under `/.cache/borg/` is the cache,
  not the repo; such calls must run in sequence or get their own cache dirs.
- **`--bypass-lock` can corrupt.** Opening a repo whose segments hold a newer commit than its index replays them and
  rewrites the index. A reader that bypasses the lock during a compaction can write a stale one. Never use it for
  anything that polls a repo that also gets compacted.
- **Vorta.** Odin's Vorta repository on Ragnarok repeatedly reports orphaned objects: wasted space, no data loss.
  `borg check --repair --archives-only` removes them, and a full check there takes hours. A running check ignores
  SIGTERM until its ssh child is killed too.
- **Vorta's settings** live in `~/.local/share/Vorta/settings.db` on Odin (tables `backupprofilemodel`,
  `sourcedirmodel`, `exclusionmodel`), not in Nix. Archives are named `{hostname}-`, so they start `Odin-`. Read
  retention and prefixes from there and from the archives, not from any copy in the config.
