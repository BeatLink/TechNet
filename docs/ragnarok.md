# Ragnarok — backup server

|          |                                                                                     |
| -------- | ----------------------------------------------------------------------------------- |
| Device   | Acer Aspire E5-575 laptop, Intel Core i3-7100U                                      |
| Platform | `x86_64-linux`                                                                      |
| Modules  | [`nix/0-common`](../nix/0-common) + [`nix/1-backup-server`](../nix/1-backup-server) |
| Address  | `ragnarok.technet`, `10.100.100.6` over WireGuard, `192.168.0.7` on the LAN         |

Ragnarok is the machine whose job is to hold backups. It is a WireGuard client,
dialling in to Heimdall. It receives borg backups from Heimdall and Odin and
holds receive-only copies of the Syncthing folders.

It ran on a Pine64 [Rock64](rock64.md) until 2026-11-21, when the Acer, which
had been Heimdall, took the role over. The backup drive moved across as it
was, so its layout and much of the history on this page come from the Rock64.
On 2026-11-22 the root moved to Heimdall's old 64 GB Dogfish SSD and the backup
drive went into the laptop's internal bay, so both disks are now on SATA.

## Hardware

12 GB RAM and two drives, both on the chipset's AHCI controller:

| Use          | Drive                             | Port                   | Identifier                                  |
| ------------ | --------------------------------- | ---------------------- | ------------------------------------------- |
| NixOS        | 64 GB Dogfish M.2 SATA SSD        | `ata3`, M.2, 6.0 Gbps  | `ata-Dogfish_SSD_64GB_5E56255506071556041`  |
| Backup drive | 5 TB 2.5" SATA HDD, `ST5000LM000` | `ata1`, bay, 3.0 Gbps  | `wwn-0x5000c500e81e231d`                    |

The laptop has three SATA ports: the internal 2.5" bay, the DVD-bay caddy and
the M.2 slot, which takes M.2 SATA. The backup drive is 15 mm thick, more than
the bay is built for, but it fits with some force. 3.0 Gbps is the drive's own
limit. No USB storage is involved any more, so the enclosure quirks, the
`storage-recover` re-probe and the explicit smartd device list from the Rock64
are gone; smartd's autodetect from the shared module finds both disks.

[`hardware-configuration.nix`](../nix/1-backup-server/1-system/hardware-configuration.nix)
matches the backup drive by serial and gives it a three-minute command timeout,
because the shingled drive pauses for long stretches while rewriting.

| Part     | Device                        | Driver  |
| -------- | ----------------------------- | ------- |
| Ethernet | Realtek RTL8411B, `a8:1e:84:32:4d:ca` | `r8169` |
| Watchdog | Intel PCH TCO timer           | `iTCO_wdt`, unused |
| Clock    | CMOS clock with its own battery | `rtc_cmos` |

[`networking.nix`](../nix/1-backup-server/1-system/networking.nix) renames the
wired NIC to `lan0` by type and takes its address by DHCP. Pi-hole on Heimdall
serves DHCP for the LAN and reserves `192.168.0.7` for the MAC above. The
initrd and the booted system each ask for a lease under a different client ID;
the reservation matches on the MAC, so both get `.7` and Pi-hole drops the
initrd's lease when the system asks. `r8169` is in the initrd so the tunnel has
a link to run over.

The laptop runs with its lid shut. logind ignores the lid switch, so closing it
does not suspend the machine, and the console blanks the built-in panel after
a minute. There is no battery fitted, so a power cut is a hard power-off.

The firmware breaks if EFI variables are written, which is why
`boot.loader.efi.canTouchEfiVariables` stays false and the machine boots the
loader from the drive's fallback path.

## Freeze recovery

[`freeze-recovery.nix`](../nix/1-backup-server/1-system/freeze-recovery.nix)
reboots a frozen machine through softdog, the kernel's software watchdog, which
systemd feeds every 30s. Softdog loads from the initrd and so is
`/dev/watchdog0`, ahead of the chipset's own TCO timer, which is left unused.

Softdog runs on a kernel timer, so a lockup hard enough to stop timers is not
recovered. The `hung_task`, `softlockup` and `hardlockup` panic sysctls and
`panic=10` cover what they can of that gap.

Nothing is sent over the network, since log lines can carry sensitive detail.
Everything goes to the persistent journal, which syncs to disk every five
seconds so a hard lockup loses little, and `memory-trail` logs memory use to it
every five seconds.

## Root drive

The root drive is btrfs subvolumes inside one LUKS container, `cryptroot`,
selected by `technet.storage.backend = "btrfs-luks"` in
[`root-drive-disko.nix`](../nix/1-backup-server/1-system/root-drive-disko.nix),
on the 64 GB Dogfish SSD. Swap is an 8 GiB swapfile on its own `@swap`
subvolume, mounted at `/swap`, so it sits inside the LUKS container and outside
the `@root` rollback.
[`swap.nix`](../nix/1-backup-server/1-system/swap.nix) puts zswap in front of it
in place of the fleet's zram. disko only creates the swapfile at format time;
the one in use was made by hand on 2026-11-24 with
`btrfs filesystem mkswapfile --size 8G`. The layout
was chosen for the Rock64, whose CPU ran OpenZFS's own AES-GCM as generic C
(see [Rock64](rock64.md#storage)); it came across unchanged, and moving this
host back to ZFS would mean a reformat. Nothing on this host is ZFS.

`btrfs-scrub@-.timer` and `btrfs-scrub@Storage.timer` scrub both filesystems
monthly.

## Backup drive

The backup drive is a single LUKS2 container holding one btrfs filesystem with
`dup` data *and* metadata, and a single subvolume `@storage` mounted at
`/Storage`. `dup` exists because there is one disk and no redundancy: without a
second copy a checksum failure is detected and *not* repairable. It halves the
drive, 2.3 TiB usable of 4.55 TiB raw, which holds the ~850 GiB stored
(2026-11-21) with room to spare.

|               |                                                                                                    |
| ------------- | -------------------------------------------------------------------------------------------------- |
| device        | `ST5000LM000-2U8170`, serial `WCJ9HXR9`, internal SATA bay                                         |
| partition     | GPT, one partition, partlabel `ragnarok-cryptstorage`                                              |
| PARTUUID      | `b701e0a4-fa98-467d-afd6-36cbca0f0737`                                                             |
| LUKS          | LUKS2, `aes-xts-plain64`, 512-bit key, **4096-byte sectors**                                       |
| LUKS KDF      | argon2id, 4 passes, ~188 MiB, 4 threads                                                            |
| LUKS UUID     | `340cfb19-e5bd-479a-a9ee-f04607540e1b`                                                             |
| mapper name   | `cryptstorage`                                                                                     |
| btrfs         | `-d dup -m dup`, label `RagnarokStorage`, crc32c                                                   |
| btrfs UUID    | `805e41b1-8d1e-4719-a557-0218ea7154ae`                                                             |
| subvolume     | `@storage`                                                                                         |
| mount options | `compress=zstd,noatime,nofail`                                                                     |
| discard       | off                                                                                                |

`/Storage/Backups` holds one borg repository per source host, and
`/Storage/Services/Syncthing` holds Syncthing's config and data directory.

### Mounting

[`data-drive.nix`](../nix/1-backup-server/1-system/data-drive.nix) opens the
container in the initrd as `cryptstorage`, with `nofail`, and mounts `/Storage`
with `nofail` and a 90 s device timeout, so a missing drive does not stop the
boot. The timeout waits on the clevis unlock, which takes about 35 s, not on
the disk. Nothing retries a missed unlock after boot; unlock by hand and start
`Storage.mount` if it happens.

### Storage guard

On 2026-11-21, while `/Storage` was not mounted, Syncthing built a fresh config
in the empty mountpoint and started syncing every folder onto the root SSD.
Since then everything that writes under `/Storage` is bound to the mount:

- `syncthing`, `syncthing-init`, `storage-directories` and each
  `borgbackup-repo-*` unit carry `RequiresMountsFor=/Storage`, so with the
  drive missing they fail instead of writing to the root drive.
- The tmpfiles rules under `/Storage` are taken out of the boot-time and
  switch-time `systemd-tmpfiles` runs and applied by `storage-directories`,
  which needs the mount.

### Recovery of 2026-11-21

The filesystem lost writes and its extent tree had to be rebuilt with
`btrfs check --repair --init-extent-tree`. A full scrub afterwards (started
10:31, 4 h 11 min) found 13,390 checksum errors: 4,802 corrected from the
second copy and **8,588 uncorrectable**. Every path the kernel logged for an
uncorrectable block was a borg segment file under `Backups/Heimdall/data` or
`Backups/Odin/data`.

As of 2026-11-21 the two borg repositories hold those damaged segments and have
not been repaired: until a `borg check --repair` has run against each and a
later check passes, treat the archives in them as unverified. Run
`btrfs scrub status /Storage` and `btrfs device stats /Storage` for the
current figures.

On the same day the drive dropped off USB once (`usb 2-2: USB disconnect` at
14:49), one of the reasons it moved to internal SATA.

### Since the move to SATA

A second full scrub on 2026-11-22 (started 13:37, 6 h 8 min, 1.64 TiB) found
3,274 checksum errors, **all corrected** from the second copy, none
uncorrectable.

Corrected checksum errors kept turning up after that scrub: about 230 between
2026-11-22 19:46 and 2026-11-24 04:10, always on mirror 1, never the same
sector twice, all in borg segments under `Backups/Odin/data` and
`Backups/Heimdall/data` written between 2026-10-29 and 2026-11-07. The scrub
had read and fixed those files, so mirror 1 went bad again after it, or reads
are coming back wrong intermittently. Whether the drive, the RAM or the read
path is at fault is not yet known. SMART reports `PASSED` with 104 reallocated
sectors, no pending or uncorrectable sectors and no CRC errors (2026-11-24).
`btrfs device stats /Storage` counts `corruption_errs` cumulatively since the
filesystem was made, so watch its growth rather than its value.

### Creating it

The passphrase is the host's `ragnarok_encryption_key`, and should stay that way: it is
what `rebind-clevis` presents when it adds the tang binding, and what lets one
typed passphrase open both containers at the console.

```sh
# On Odin, from the TechNet checkout:
sops -d --extract '["ragnarok_encryption_key"]' secrets/admin/nixtool.yaml | ssh ragnarok.technet sudo install -m 600 /dev/stdin /tmp/dk.key

# Both partition ends must land on 4096-byte boundaries -- see below
TOTAL=$(sudo blockdev --getsz /dev/sdX)
LAST=$((TOTAL - 34)); END=$((LAST - ((LAST - 7) % 8)))
sudo sgdisk --zap-all /dev/sdX
sudo sgdisk --new=1:2048:$END --typecode=1:8309 --change-name=1:ragnarok-cryptstorage /dev/sdX
sudo partprobe /dev/sdX && sudo udevadm settle
sudo wipefs -a /dev/sdX1

sudo cryptsetup luksFormat --type luks2 --sector-size 4096 \
    --pbkdf argon2id --pbkdf-memory 262144 --pbkdf-parallel 4 \
    --batch-mode --key-file /tmp/dk.key /dev/sdX1
sudo cryptsetup open --key-file /tmp/dk.key /dev/sdX1 cryptstorage

sudo mkfs.btrfs -d dup -m dup -L RagnarokStorage /dev/mapper/cryptstorage
sudo mount /dev/mapper/cryptstorage /mnt/newstorage
sudo btrfs subvolume create /mnt/newstorage/@storage
sudo umount /mnt/newstorage
sudo mount -o subvol=@storage,compress=zstd,noatime /dev/mapper/cryptstorage /mnt/newstorage
```

A new container gets a new PARTUUID, which
[`data-drive.nix`](../nix/1-backup-server/1-system/data-drive.nix) names, and
its tang binding from `rebind-clevis Ragnarok` on Odin.

Things that are not obvious:

**4096-byte sectors, and the alignment arithmetic.** The drive reports
`4096-byte physical blocks`, but `cryptsetup` defaults to 512-byte sectors,
which makes dm-crypt read-modify-write every partial block. Asking for
`--sector-size 4096` then fails with *"Device size is not aligned to requested
sector size"* unless the partition is a whole number of 4 KiB blocks. `sgdisk`
aligns the *start* to 1 MiB by default but ends the partition at the last usable
sector, which generally is not aligned. With `start = 2048`, the size is a
multiple of 8 sectors only when `end ≡ 7 (mod 8)` — which is what the `END`
arithmetic above produces.

**Verify, do not trust a chained `echo`.** `cryptsetup ... | tail` reports
`tail`'s exit status, so a `&& echo OK` after a pipeline will happily print OK
over a failed format. Check `$?` on the command itself, or `cryptsetup luksDump`
afterwards.

**Copying the backup tree needs `--numeric-ids`.** `borg` is uid 999 here and
999 is `colord` on Odin, so an `rsync` by name rewrites ownership of the whole
tree. Use `rsync -aHAX --numeric-ids`, and `--delete-before` when refreshing a
stale copy, because borg compacts and the old segments have to go before the
new ones land.

**`dup` on a shingled drive slows as it fills.** Both copies are written, so
the logical rate is half the disk rate, and the disk rate fell from about
90 MB/s to about 34 MB/s as the platter filled. Budget about 11 hours to write
966 GB.

## Backups

Borg is configured in [`borg.nix`](../nix/1-backup-server/1-system/borg.nix):
one repository per source host, `/Storage/Backups/Heimdall` and
`/Storage/Backups/Odin`, each authorised only for that host's own borg key. The
`Z` tmpfiles rule there keeps the whole tree owned by `borg`.

The backups, prunes, compacts and checks are driven by X-Backups on Heimdall
([`x-backups.nix`](../nix/2-server/3-services/backups/x-backups.nix)) as the
`heimdall-ragnarok` and `odin-ragnarok` repositories, which also hold the
weekly repository and archive checks and the monthly extract and
`--verify-data` checks.

btrfs cannot stand in for those checks. A segment whose bytes were already
wrong when borg handed them over checksums clean at the filesystem layer, which
is how a `Segment entry checksum mismatch` sat undetected in this repository
from 2026-09-06 until a borg check found it.

## Unlocking

Both containers are made with the same passphrase, `ragnarok_encryption_key`
in `secrets/admin/nixtool.yaml`, and each carries a clevis binding to Odin's
tang server in its LUKS2 header, written by `rebind-clevis Ragnarok` on Odin
through [`clevis.nix`](../nix/1-backup-server/1-system/clevis.nix). At boot,
systemd-cryptsetup puts up a password prompt for each container as its disk
appears, and three things can answer it:

- **The console.** Plymouth shows the prompt on the laptop's screen.
- **The initrd sshd.** `ssh ragnarok-boot` reaches it over WireGuard at
  `10.100.100.6`, or on the LAN at `192.168.0.7`; logging in runs the password
  agent first and drops to bash once nothing is pending.
- **Tang.** nixpkgs' `boot.initrd.clevisLuksAskpass` runs clevis' own
  askpass loop, which watches the prompts and answers them from the header
  bindings. It retries for as long as a prompt is pending and reaches Odin
  through the tunnel at `10.100.100.2` or on the LAN at `192.168.0.3`. It never
  touches the cryptsetup unit, so the prompt stays open for the other two the
  whole time.

Typing the passphrase once is enough: systemd-cryptsetup caches an entered
passphrase in the kernel keyring, and the other container's prompt re-checks
the keyring the moment the first is answered.

Odin's tang only serves while it has been switched on from Odin's panel applet,
so Ragnarok **will not unlock on its own** unless that is on, or someone types.
The WireGuard recovery loop from the shared module restarts networkd from 45s
into the initrd if the tunnel is not carrying traffic, so a tunnel that came up
before DNS did is not a dead end. A backup drive that missed the initrd stays
locked until someone unlocks it.

`rebind-clevis Ragnarok` on Odin rebinds both headers against the current tang
keys and is also how a fresh container gets its first binding; it needs tang
reachable. `clevis luks list -d <device>` shows the binding, and
`journalctl -b -u clevis-luks-askpass` shows what askpass did during the boot.

## IR blaster

[`ir-blaster`](../nix/1-backup-server/3-services/ir-blaster/default.nix) sends IR
from a CH340 (`1a86:7523`) USB serial adapter's TX pin driving a three-wire
emitter, which works better on 5 V than 3.3 V. Mark bytes at a baud near a
multiple of the 38 kHz carrier make the carrier; the dark fill between them
flickers at the byte rate, which nearby receivers see, so the service picks a
rate that puts the fill far above it. The page answers over WireGuard only, on
port 9621.

Learning goes through [`ir-learn`](../nix/0-common/3-services/ir-learn/default.nix)
and a USB sound card's microphone input, not the CH340: the receiver eye passes
the raw carrier without demodulating it, and the CH340 blanks bytes with framing
errors to `00`. Wire the eye's red to 5 V, black to the sleeve and white to the
tip, with AGC off and gain at 0. The built-in headphone output tops out at 48 kHz
and cannot send a 38 kHz carrier.

## Planned move

Ragnarok is to move to another house as the off-site backup. The move waits on
the backup drive: the repositories have to be repaired and checked clean first,
and the checksum errors that continue after the 2026-11-22 scrub have to be
explained.
There it has to unlock unattended, which today depends on Odin's tang being
switched on and reachable over WireGuard; until that changes, a reboot there
waits on the console or on someone answering over `ssh ragnarok-boot`.

## Reinstalling

The root SSD can be taken out and reinstalled from Odin with disko and
`nixos-install`, as it was on 2026-09-09 and again onto the Dogfish on
2026-11-22 with
[`install-ragnarok-dogfish.sh`](../scripts/install-ragnarok-dogfish.sh). Before
wiping it, copy `/persistent` off:

- `etc/ssh/`, the host and initrd host keys; sops decrypts this host's secrets
  with the host key, and the initrd secrets are appended at install time.
- `var/lib/nixos/uid-map`, which records `borg` at uid 999. Lose it and a fresh
  install can give `borg` another uid, after which the `Z` rule in
  [`borg.nix`](../nix/1-backup-server/1-system/borg.nix) recursively chowns the
  whole backup tree.
- `var/lib/syncthing-database`, the Syncthing index, which otherwise means
  rehashing every folder on the shingled drive.

Restore them into `/mnt/persistent/` before `nixos-install`, then bind the new
container with `rebind-clevis Ragnarok`. The backup drive is untouched by a
root reinstall.

## Rebuilding

Ragnarok is the `ragnarok` deployment in X-Nix, built on Heimdall and switched by
its own agent; it switches automatically when the flake changes.
