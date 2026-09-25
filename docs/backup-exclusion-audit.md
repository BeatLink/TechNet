# Backup exclusion audit — Odin's Vorta profiles

| | |
| --- | --- |
| Date | 2026-09-22 |
| Host | Odin |
| Scope | The three Vorta profiles that back up `/Storage`: *1. On Disk*, *2. Heimdall*, *3. Ragnarok* |
| Status | Every change under *Work done* at the end of this file has been applied; the findings above describe the state that prompted them |

Vorta's exclusions live in `~/.local/share/Vorta/settings.db`, not in this flake, so they are
recorded here instead. Each profile carries a set of named presets (shipped with Vorta, expanded
into borg `fm:` patterns) plus raw patterns of its own.

## Method

- `exclusionmodel` and `backupprofilemodel` read out of `settings.db` per profile.
- Preset slugs expanded from Vorta's own `assets/exclusion_presets/*.json`, so a preset that matches
  nothing on this host could be told apart from one that works.
- On-disk sizes measured with `du` under `/Storage`. These are live sizes, not deduplicated repo
  sizes; what a backup actually holds is smaller.

## 1. The three profiles had drifted

All three agreed on 15 entries. The rest did not:

| Exclusion | On Disk | Ragnarok | Heimdall | Cost where missing |
| --- | --- | --- | --- | --- |
| `cache-files` | missing | on | on | ~5.5G: Vorta's own borg cache 4.7G, thumbnails 539M, Firefox cache 243M |
| `temp-files` | missing | on | on | small, but `*.part`/`*.bak` churn re-chunks every run |
| `log-files` | missing | on | on | small |
| `recycle-bin-trash` | missing | on | on | whatever is in the trash at backup time |
| `vm-container-files` | missing | on | off | 11G of `/Storage/Files/ISOs`, via `fm:*.iso` |
| `java-development-artefacts` | missing | missing | on | nothing measurable; `.gradle` is already caught by `android-studio` |
| `media-files` | missing | missing | off | see below |
| Steam `steamapps/common` | on | missing | missing | 103G, on both remotes |

The on-disk profile was the least excluded of the three except for Steam, which only it excluded.

## 2. Two presets matched nothing on this host

- **`firefox-cache`** targets `*/.mozilla/firefox/...`. This flake persists Firefox at
  `.config/mozilla` (`/Storage/Apps/Core/Firefox`, 4.9G), so none of its patterns fired. The 243M
  under `.cache/mozilla` was caught by `cache-files` instead — which the on-disk profile lacked.
- **`vscode-cache`** targets `.config/Code`. VSCodium writes `.config/VSCodium`, so it fired on
  nothing either.

Both are kept enabled for the paths they do cover on other hosts, with raw patterns added for the
real ones.

## 3. Regenerable content no profile excluded

| Path | Size | Disposition |
| --- | --- | --- |
| `~/.lmstudio/models`, `extensions`, `disabled-mmproj` | 41G | Excluded. Now named declaratively in `nix/3-laptop/4-apps/programming/lm-studio.nix` and fetched from Hugging Face on demand. |
| `~/.stremio-server/stremio-cache` | 5.5G | Excluded; pure streaming cache. |
| `*/target` (Rust build output) | 4.3G | Excluded. `rust-artefacts` only covers `~/.cargo` and `~/.rustup`. |
| `~/.claude/tmp` | 2.5G | Excluded; session scratchpads. |
| VSCodium `Service Worker`, `Cache`, `CachedData`, `CachedExtensionVSIXs` | ~1.0G | Excluded. |
| Trilium `Cache`, `Code Cache`, `GPUCache`, `Partitions` | ~880M | Excluded. `trilium-data` (1.8G) is real data and is kept. |
| `*/dist`, `*/build` | 730M | Excluded. |
| `~/.claude/worktrees` | 7.4G | Excluded. Anything committed is in `.git` already; uncommitted worktree changes are not recoverable. |
| `/Storage/Apps/System/ShaderCache` | 43M | Kept; regenerable but trivial. |

Electron caches are excluded by shape rather than per app: `Code Cache`, `GPUCache`, `DawnCache`,
`CachedData` and `CacheStorage` wherever they appear, plus `htmlcache` and `cef/cache`. Anchoring
these under `.config/*` is not enough — Stremio keeps 1.3G under `.local/share`, Steam another 269M,
and the whole `/Storage/PhoneApps` tree has no `.config` in its paths at all.

## 4. What was deliberately not excluded

- **`media-files` stays off.** Its patterns are unanchored (`fm:*.mp3`, `fm:*.mkv`, …), so it would
  drop `/Storage/Files/Music` (14G), `Videos` (15G) and `Sounds` (30G) — 59G that exists nowhere
  else.
- **`vm-container-files` was turned off everywhere,** including on Ragnarok where it had been on.
  `/Storage/System/LibVirt` holds 72K, so there are no VM disks for it to catch; what it actually
  excluded was the 11G of ISOs, and any other `.iso` on the pool. Ragnarok had been silently
  skipping those.
- **`/Storage/Files/Projects/3ptech/Sysadmin Knowledgebase`** (59G) is not regenerable and is kept.
- **Firefox site storage is kept**, 4.6G on the desktop profile and 4.2G on the phone one. Most of
  `storage/default` regenerates from the sites themselves, but offline apps keep state there that
  exists nowhere else, so the space is accepted. Only the profile's telemetry, crash and
  start-up-cache directories are excluded.

## 5. Existing archives

New exclusions only affect new archives. Content already in a repository has to be rewritten out of
it with `borg recreate --exclude ...` followed by `borg compact`; `recreate` reuses existing chunks
for the files it keeps, so it does not re-read the source, but `compact` is what reclaims the space.

All three repositories were rewritten on 2026-09-22 against the full exclusion set above. The
on-disk one had `steamapps/common` removed first and then the rest; Heimdall followed over the link;
Ragnarok was offline at the time and ran as soon as it answered SSH.

## Work done

- `cache-files`, `temp-files`, `recycle-bin-trash` and `java-development-artefacts` enabled on all
  three profiles.
- `vm-container-files` turned off on all three, so ISOs are backed up again.
- `media-files` present and off on all three, so it is a recorded decision rather than an omission.
- The Steam `steamapps/common` exclusion extended from the on-disk profile to both remotes.
- Raw patterns added to all three for the LM Studio models, the Stremio cache, Rust `target`,
  `dist`, `build`, `~/.claude/tmp`, `~/.claude/worktrees`, the VSCodium and Trilium caches, the
  generic Electron caches, and the in-profile Firefox caches that `firefox-cache` misses.
- All three repositories rewritten with `borg recreate` and compacted, so the exclusions apply to
  the archives that already existed as well as to new ones.
- `nix/3-laptop/4-apps/programming/lm-studio.nix` grew a declarative list of the wanted model files
  and a `lm-studio-models` user service that fetches any that are missing from Hugging Face.
