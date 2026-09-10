# Ragnarok — backup server

|          |                                                                                       |
| -------- | ------------------------------------------------------------------------------------- |
| Device   | Pine64 Rock64 SBC, Rockchip RK3328                                                    |
| Platform | `aarch64-linux`                                                                     |
| Modules  | [`nix/0-common`](../nix/0-common) + [`nix/1-backup-server`](../nix/1-backup-server) |
| Address  | `ragnarok.technet` over WireGuard                                                   |

Ragnarok is a low-power SBC whose job is to hold backups. It is a WireGuard
client, dialling in to Heimdall.

It lives off site, at family's home, so that the backups survive physical damage
to or destruction of the house the rest of the network is in. That placement is
why it dials in over WireGuard rather than sitting on the LAN.

Despite both being quad Cortex-A53 aarch64, it shares no silicon with Thor:
Ragnarok is Rockchip RK3328, Thor is Allwinner A64. Nothing vendor-specific
transfers between them — different U-Boot targets, different DTBs, and recovery
is Rockchip maskrom rather than Allwinner FEL. Its ethernet is `dwmac_rk` +
`stmmac`, both in the initrd so the tunnel has a link to run over.

## Hardware

2 GB RAM, and three drives — nothing is internal, both the system and the data
live on USB-attached 2.5" disks:

| Use          | Size   | Format            |
| ------------ | ------ | ----------------- |
| Tow-Boot     | 32 GB  | MicroSD card      |
| NixOS        | 128 GB | 2.5" SATA USB SSD |
| Backup drive | 5 TB   | 2.5" SATA USB HDD |

Two things to know before touching it physically:

- It will not drive certain monitors over HDMI directly. An Xtech HDMI-to-VGA
  adapter in between works.
- Serial is the reliable console. Wire black to GND, white to RXD, brown to TXD,
  then:

  ```sh
  nix-shell -p minicom --run 'sudo minicom -D /dev/ttyUSB0 -b 115200 --color=on'
  ```

References — [product page](https://pine64.com/product/rock64-2gb-single-board-computer/),
[ROCK64 wiki](https://wiki.pine64.org/wiki/ROCK64),
[software releases](https://wiki.pine64.org/wiki/ROCK64_Software_Releases).

## Tow-Boot

Ragnarok boots U-Boot built through Tow-Boot. This board has no SPI flash, so
the Tow-Boot *shared disk image* goes on the 32 GB SD card instead. That is what
lets the board boot any UEFI aarch64 ISO or drive, with no board-specific imaging
or partition layout required on the target media.

It builds from a fork, on the `rock64-pinephone-fixes` branch — ROCK64/RK3328
support on the fork's own Tow-Boot U-Boot tree (2026.04), with the Tow-Boot menu
on HDMI and USB keyboard input. [Tow-Boot](tow-boot.md) describes the fork; the
source is
[BeatLink/Tow-Boot](https://github.com/BeatLink/Tow-Boot/tree/rock64-pinephone-fixes):

```sh
git clone https://github.com/BeatLink/Tow-Boot -b rock64-pinephone-fixes
nix-build --arg src ./Tow-Boot -A pine64-rock64
dd if=shared.disk-image.img of=/dev/XXX bs=1M oflag=direct,sync status=progress
```

## Storage

The root drive is btrfs subvolumes inside one LUKS container, selected by
`technet.storage.backend = "btrfs-luks"` in
[`root-drive-disko.nix`](../nix/1-backup-server/1-system/root-drive-disko.nix).
The backup drive followed a day later and is now its own LUKS container holding
btrfs -- see [Data drive](#data-drive). Nothing on this host is ZFS any more,
which is what `technet.storage.zfsDataPool = false` says in
[`data-drive.nix`](../nix/1-backup-server/1-system/data-drive.nix).

The root drive moved off ZFS because OpenZFS carries its own crypto and never
calls the kernel crypto API, so its AES-GCM runs as generic C on a CPU that has
`aes` and `pmull` sitting idle — 53% of this board's CPU went to
`gcm_generic_mul` and friends under load. dm-crypt is GPL kernel code and does
reach those instructions. `cryptsetup benchmark` on Ragnarok, under a load
average of 5:

| cipher | encryption | decryption |
| ------ | ---------- | ---------- |
| aes-xts 256b | 142.4 MiB/s | 91.9 MiB/s |
| aes-cbc 256b | 31.5 MiB/s | 31.3 MiB/s |

`/proc/crypto` here offers `xts-aes-ce`, which is the driver doing the work —
`aes-cbc` in the same run shows what the same CPU manages without it. Thor
measured 21.8/23.8 MB/s writing and reading through a ZFS `aes-256-gcm` dataset
on the same Cortex-A53 silicon; a cipher benchmark and a filesystem are not the
same measurement, but they point the same way.

Since `encryption` is immutable on a ZFS dataset, the change is a reinstall.
The backup drive is untouched by it, so what has to survive is
`/persistent` — see below.

That also means the configuration cannot be *switched* into. A running ZFS
Ragnarok rebuilt against `btrfs-luks` gets a `fileSystems` table pointing at a
`/dev/mapper/cryptroot` that does not exist, and boots no further. The install
below is how this lands, and nothing before it should be deployed with
`nixos-rebuild switch`.

## Installing NixOS

Installed from Odin, the same way Thor is: the root SSD is USB-attached, so it
can simply be moved. These are `install/install-local`'s own steps, split apart
because one thing has to happen in the middle of them — step 2 says why. The
board's own installer path still works and is described at the end, but it
builds on a 2 GB Rock64.

Done this way on 2026-09-09, moving the root drive off ZFS.

### 1. Rescue /persistent

Roughly 250 MB, and almost none of it is reproducible. The drive is USB, so this
works with it already pulled and attached to Odin — import the old pool
read-only rather than needing the board up:

```sh
sudo zpool import -f -N -o readonly=on -R /mnt/ragnarok-old -d /dev/sdX3 root-pool-Ragnarok
sudo zfs load-key -L file:///run/secrets/ragnarok_zfs_passphrase root-pool-Ragnarok/root
sudo zfs mount root-pool-Ragnarok/root/persistent
sudo cp -a --preserve=all /mnt/ragnarok-old/persistent/. ./ragnarok-persistent/
sudo zpool export root-pool-Ragnarok
```

By name and by device, never `zpool import -a`: Odin's own pools are imported.

Two things in there are the reason this step exists.
`var/lib/syncthing-database` is 221 MB of index; lose it and Syncthing rehashes
the whole share on a shingled USB disk attached to a 2 GB board.
`var/lib/nixos/uid-map` records `borg` at uid 999, and `borg` owns every byte of
`/Storage/Backups` on a pool this install does not touch — lose the map and a
fresh install can allocate `borg` a different uid, at which point the `Z` rule in
[`data-drive.nix`](../nix/1-backup-server/1-system/data-drive.nix) recursively
chowns 1.9 TB to repair it.

### 2. Keep clevis on, and seed the JWE

Thor's install turns `technet.clevis.enable` off, because the JWEs become
`boot.initrd.secrets` entries copied during *activation* and a fresh
`/persistent` holds none. Ragnarok does not have to: a JWE is nothing but the
host passphrase encrypted to tang, and clevis binds one passphrase per host, so
the JWE rescued from the old *root pool* is already a valid secret for the new
`cryptroot`. Copy it under the new name before `nixos-install` runs and the
first boot unlocks unattended, with no rebuild afterwards on a board that takes
20 minutes to switch.

Confirm it decrypts to what LUKS is about to be given, before relying on it:

```sh
sudo clevis decrypt < ./ragnarok-persistent/etc/clevis/root-pool-Ragnarok-root.jwe \
  | cmp - /run/secrets/ragnarok_zfs_passphrase && echo match
```

### 3. Partition, seed, install

That seeding has to land between partitioning and `nixos-install`, which
`install/install-local` runs as one command, so these are its own steps. They
are otherwise exactly what the tool does.

```sh
nix build --no-link --print-out-paths \
  /Storage/Files/Projects/TechNet#nixosConfigurations.Ragnarok.config.system.build.toplevel

sudo sh -c 'printf "%s" "$(cat /run/secrets/ragnarok_zfs_passphrase)" > /tmp/encryption.key'
sudo chmod 600 /tmp/encryption.key

sudo "$(nix build --impure --no-link --print-out-paths --expr \
  '((builtins.getFlake "/Storage/Files/Projects/TechNet").nixosConfigurations."Ragnarok".extendModules {
      modules = [ ({ lib, ... }: {
        nixpkgs.hostPlatform = lib.mkForce builtins.currentSystem;
        disko.devices.disk.root-drive.device = lib.mkForce "/dev/sdX";
      }) ];
    }).config.system.build.diskoScript')"
```

`hostPlatform` is forced to Odin's because the partitioning runs here; built
from Ragnarok's own platform the script carries aarch64 binaries. The disk is
identified by serial — `SATA_SSD`, `22020812000605` — and it is a local disk on
Odin, so a wrong path destroys Odin's data.

disko leaves everything mounted under `/mnt`. Restore into it, rename the JWE,
and install:

```sh
sudo cp -a --preserve=all ./ragnarok-persistent/. /mnt/persistent/
sudo cp -a /mnt/persistent/etc/clevis/root-pool-Ragnarok-root.jwe /mnt/persistent/etc/clevis/cryptroot.jwe
sudo rm -f /mnt/persistent/etc/clevis/root-pool-Ragnarok-root.jwe

sudo nixos-install --root /mnt --no-root-passwd --system /nix/store/…-nixos-system-Ragnarok-…
sudo umount -R /mnt && sudo cryptsetup close cryptroot && sudo rm -f /tmp/encryption.key
```

The restore carries the real `machine-id` in with it, so this never leaves the
literal string `uninitialized` in `/persistent/etc/machine-id` the way a bare
install does.

### 4. Check the initrd before unplugging

The whole unattended boot rests on four files having been appended to the
initrd, so look rather than hope:

```sh
zstd -dc /mnt/boot/EFI/nixos/*-initrd.efi | strings | grep -oE "\.initrd-secrets/[a-zA-Z0-9/_.-]+"
```

`etc/clevis/cryptroot.jwe`, `etc/clevis/data-pool-Ragnarok/storage.jwe`,
`persistent/etc/ssh/ssh_initrd_host_ed25519_key` and
`run/secrets/wireguard_private_key` all have to be there. The last two are
decrypted by sops during the install, which only works because the host key was
restored in step 3 — the file in `/boot` being named by hash rather than by
store path is what says the append ran at all.

### 5. First boot

Reattach the drive to the Rock64 and power it on. Nothing should need typing:
clevis unlocks `cryptroot` from the seeded JWE and the backup pool from its own.
Then check that `/Storage` came back, that `borg` still owns it by name *and* by
number, and that `btrfs-scrub-root.timer` is armed.

If it does sit on a password prompt, the tang servers were unreachable. The
initrd sshd is the way in, and `luksMaxAttempts = 0` means the retry loop is
still trying behind it.

### The installer path

Still available, and the only option if the SSD cannot be moved: NixOS Minimal
aarch64 on a USB stick, all other drives disconnected, root drive attached after
the boot screen loads, `passwd` for root, then swap on a spare partition and
`mount -o remount,size=10G,noatime /nix/.rw-store` before installing. Building
on 2 GB of RAM is the reason this is the fallback.

## Backups

Borg is configured in [`borg.nix`](../nix/1-backup-server/1-system/borg.nix),
with the repository living on the data drive from
[`data-drive.nix`](../nix/1-backup-server/1-system/data-drive.nix). Other
hosts push to it; the `borg` group on each client grants repo access.

## Unlocking

Clevis against Odin's tang, enabled in
[`clevis.nix`](../nix/1-backup-server/1-system/clevis.nix), passphrase in
`secrets/1-backup-server/clevis.yaml`. Two targets, one secret: the `cryptroot`
LUKS container and the `data-pool-Ragnarok/storage` dataset.

As a WireGuard *client*, its initrd recovery loop probes the server through the
tunnel (`10.100.100.1` out of `wg0`) rather than probing the LAN, since for a
client it is the tunnel itself that has to work. That is also why
`luksMaxAttempts = 0` here: the shared LUKS retry stops after five attempts by
default so it cannot keep cancelling the password prompt of someone trying to
type, and on a headless host off site there is no one to protect. It retries
until the tunnel comes up, the way the ZFS loop beside it always has.

If it never does, the initrd sshd is the way in.

## Data drive

The backup drive is a single LUKS2 container holding one btrfs filesystem with
`dup` data *and* metadata, and a single subvolume `@storage` mounted at
`/Storage`. It replaced `data-pool-Ragnarok`, a ZFS pool, on 2026-09-10, for the
same reason the root drive moved: OpenZFS never calls the kernel crypto API, so
its AES-GCM ran as generic C on a CPU whose `aes`/`pmull` instructions sat idle.
The ZFS dumps in [`ragnarok-data-pool/`](ragnarok-data-pool) are now historical.

`dup` is the btrfs equivalent of the `copies=2` the ZFS dataset carried, and it
exists for the same reason: one disk, no vdev redundancy, so without a second
copy a checksum failure is detected and *not* repairable. It halves the drive —
2.3 TiB usable of 4.55 TiB raw — which is ample for ~970 GiB of data.

| | |
| --- | --- |
| device | `ST5000LM000-2U8170`, serial `WCJ9HXR9`, USB via SABRENT `152d:0583` |
| partition | GPT, one partition, partlabel `ragnarok-cryptstorage` |
| PARTUUID | `b701e0a4-fa98-467d-afd6-36cbca0f0737` |
| LUKS | LUKS2, `aes-xts-plain64`, 512-bit key, **4096-byte sectors** |
| LUKS KDF | argon2id, 256 MiB memory, 4 threads, ~370k iterations |
| LUKS UUID | `340cfb19-e5bd-479a-a9ee-f04607540e1b` |
| mapper name | `cryptstorage` |
| btrfs | `-d dup -m dup`, label `RagnarokStorage`, crc32c |
| btrfs UUID | `805e41b1-8d1e-4719-a557-0218ea7154ae` |
| subvolume | `@storage` |
| mount options | `compress=zstd,noatime` |
| discard | **off** — the USB bridge passes none, so `allowDiscards` would leak the free-space map for nothing |

### Creating it

Run from Odin with the drive attached there, because the Rock64 only has one
USB 3 port and its own root SSD occupies it. `152d:0583` needs its UAS quirk on
whatever host it is plugged into or it comes up unusable:

```sh
echo "152d:0583:uf" | sudo tee /sys/module/usb_storage/parameters/quirks
```

The passphrase is the host's `zfs_passphrase`, and must stay that way: clevis
binds one secret per host and feeds it to every target, so a container made with
a different passphrase can never be unlocked at boot.

```sh
sudo sh -c 'printf "%s" "$(cat /run/secrets/ragnarok_zfs_passphrase)" > /tmp/dk.key'
sudo chmod 600 /tmp/dk.key

# Both partition ends must land on 4096-byte boundaries -- see below
TOTAL=$(sudo blockdev --getsz /dev/sdX)
LAST=$((TOTAL - 34)); END=$((LAST - ((LAST - 7) % 8)))
sudo sgdisk --zap-all /dev/sdX
sudo sgdisk --new=1:2048:$END --typecode=1:8309 --change-name=1:ragnarok-cryptstorage /dev/sdX
sudo partprobe /dev/sdX && sudo udevadm settle
sudo wipefs -a /dev/sdX1                      # old ZFS labels survive repartitioning at the same offset

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

Three things that are not obvious:

**4096-byte sectors, and the alignment arithmetic.** The drive reports
`4096-byte physical blocks`, but `cryptsetup` defaults to 512-byte sectors,
which makes dm-crypt read-modify-write every partial block. Asking for
`--sector-size 4096` then fails with *"Device size is not aligned to requested
sector size"* unless the partition is a whole number of 4 KiB blocks. `sgdisk`
aligns the *start* to 1 MiB by default but ends the partition at the last usable
sector, which generally is not aligned. With `start = 2048`, the size is a
multiple of 8 sectors only when `end ≡ 7 (mod 8)` — which is what the `END`
arithmetic above produces.

**The KDF cost is capped on purpose.** `cryptsetup` benchmarks the machine it
runs on to pick argon2 parameters, and this container is created on Odin but
unlocked in Ragnarok's initrd — 2 GB of RAM on a Cortex-A53. `--pbkdf-memory
262144` (256 MiB) keeps the unlock inside what that board can afford. Nothing is
really lost: the passphrase is 50 bytes of sops-held entropy, so KDF hardening
is not what stands between an attacker and the disk.

**Verify, do not trust a chained `echo`.** `cryptsetup ... | tail` reports
`tail`'s exit status, so a `&& echo OK` after a pipeline will happily print OK
over a failed format. Check `$?` on the command itself, or `cryptsetup luksDump`
afterwards.

### Migrating the data

There is one drive, so the data has to go somewhere else and come back. It was
staged on a 1 TB SSD (`/Storage/Backups`, which fits with ~15 GiB spare) and on
Odin's own pool (`/Storage/Files`, 76.5 GB), then written back after the format.

```sh
# stage, with the source imported read-only so it stays a rollback
sudo zpool import -f -N -o readonly=on -R /mnt/src -d /dev/sdX1 data-pool-Ragnarok
sudo zfs load-key -L file:///run/secrets/ragnarok_zfs_passphrase data-pool-Ragnarok/storage
sudo zfs mount data-pool-Ragnarok/storage
sudo rsync -aHAX --numeric-ids --delete-before /mnt/src/Storage/Backups/ /mnt/stage/Backups/
sudo rsync -n -aHAX --numeric-ids --delete-before -i /mnt/src/Storage/Backups/ /mnt/stage/Backups/   # verify: no output
sudo zpool export data-pool-Ragnarok
# ... format per above ...
sudo rsync -aHAX --numeric-ids /mnt/stage/Backups/ /mnt/newstorage/Backups/
```

`--numeric-ids` is not optional: `borg` is uid 999 on Ragnarok and 999 is
`colord` on Odin, so names would rewrite ownership of the whole backup tree.
`--delete-before` rather than the default `--delete-during`, because borg
compacts its repo — a stale copy holds segments that no longer exist upstream,
and on a nearly-full staging disk those have to be freed *before* the new ones
land.

### Putting it back on Ragnarok

The config in `data-drive.nix` cannot be deployed before the drive's JWE exists,
for the same reason the root drive's could not: `boot.initrd.clevis.devices`
becomes a `boot.initrd.secrets` entry read during *activation*, so a rebuild
without it fails. And as with `cryptroot`, no new secret is needed -- a JWE is
just the host passphrase encrypted to tang, so any of the host's own JWEs works
under the new name:

```sh
sudo cp /persistent/etc/clevis/cryptroot.jwe /persistent/etc/clevis/cryptstorage.jwe
sudo rm -f /persistent/etc/clevis/data-pool-Ragnarok-storage.jwe   # its dataset is gone
sudo nixos-rebuild boot --flake .#Ragnarok
```

Order matters: reattach the drive and boot on the *old* config first (`/Storage`
is `nofail`, so it comes up without it), seed the JWE, then rebuild. Deploying
first leaves a host that fails to rebuild until someone puts the file there.

Two measurements worth keeping:

**The staging SSD needs UAS, not for speed but for TRIM.** Under `usb-storage`
(BOT) the bridge advertises `DISC-GRAN 0B`, so the ~150 GB `--delete-before`
freed stayed invisible to the controller and writes collapsed to 17 MB/s
fighting garbage collection. Quirking `152d:0576` with `f` instead of `uf` keeps
it on `uas`, where discard works: `fstrim` released 149.8 GiB in 18 seconds and
writes went to 195 MB/s. Note this contradicts the "both aborted under UAS"
comment in `data-drive.nix` — `0576` is fine under UAS with `NO_REPORT_OPCODES`.
An SSD filled past ~96% slows down again regardless, and no amount of trimming
helps that.

**`dup` on a shingled drive is not disproportionately slow.** Measured during
the write-back: 90.7 MB/s written to the drive at 100% utilisation while the
source SSD read 45.4 MB/s — exactly half, which is both copies going down. So
the logical rate is ~45 MB/s and 966 GB takes ~6 hours. Reading the source over
USB 3 on Odin managed 128 MB/s, against roughly 35-40 MB/s on the Rock64, whose
only USB 3 port is taken by the root SSD.

## As a build host

Ragnarok is the only native `aarch64-linux` machine in the network. Odin can
build aarch64 closures through binfmt, but that is qemu emulation and slow.
Adding Ragnarok to `nix.buildMachines` on Odin would make Thor's builds native.

Two caveats: it is a modest SBC, so it is faster than emulation but not fast in
absolute terms, and it must be awake and unlocked to be useful — which, per the
tang arrangement, means Odin must be unlocked too.

## Rebuilding

```sh
nixtool run maintenance/rebuild --host Ragnarok --action dry-activate
nixtool run maintenance/rebuild --host Ragnarok --action switch
```

Builds for Ragnarok run on Odin under emulation unless a native builder is
configured, so expect them to take noticeably longer than Heimdall's.
