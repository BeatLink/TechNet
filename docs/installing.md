# Installing — traps common to every host

Each host's own page has its install steps. These apply to all of them.

## Seed /persistent before the first boot

- **Clevis JWEs.** `rebind-clevis` encrypts only the host's passphrase and writes the same ciphertext once per
  target, so any of a host's JWEs is valid for a new target under a new name. They are `boot.initrd.secrets`,
  copied during activation, so seeding them into `/mnt/persistent/etc/clevis` between disko and `nixos-install`
  makes the first boot unlock unattended. This means driving the install by hand, since `install/install-local`
  runs disko and `nixos-install` as one command.
- **SSH host keys.** With `/mnt/persistent/etc/ssh` seeded first, sops secrets decrypt during `nixos-install`,
  which gets the WireGuard key and the initrd host key into the initrd.
- **machine-id.** Run `systemd-id128 new > /mnt/persistent/etc/machine-id`. Otherwise the file keeps NixOS's
  `uninitialized` marker, systemd never commits an ID, and every boot gets a random one on a read-only tmpfs.
  To fix a host already affected, write `cat /etc/machine-id` into `/persistent/etc/machine-id` and
  `umount /etc/machine-id`.

## The bootloader step fails on a fresh /persistent

`nixos-install` does everything but the bootloader and exits 1 with `failed to create initrd secrets!`, because
`boot.initrd.secrets` includes `/run/secrets/wireguard_private_key` and `switch-to-configuration boot` never runs
activation. `nixos-enter` puts a tmpfs on `/run`, so activation and whatever reads `/run/secrets` must run in the
same session. With the host key already in `/mnt/persistent/etc/ssh/`:

```sh
sudo nixos-enter --root /mnt -- bash -c '/nix/var/nix/profiles/system/activate && /nix/var/nix/profiles/system/sw/bin/rebind-clevis'
sudo nixos-enter --root /mnt -- bash -c '/nix/var/nix/profiles/system/activate && /nix/var/nix/profiles/system/bin/switch-to-configuration boot'
```

The ESP is mounted `umask=0077`, so inspect it under sudo, or a glob silently expands to nothing.

## Clevis at boot

LUKS hosts unlock from `clevis luks bind` header tokens through
clevis-luks-askpass, which answers the pending prompt. Heimdall's ZFS still uses
JWE files in `/persistent/etc/clevis` and a retry loop, since nixpkgs has no ZFS
askpass. Each device gets its own random slot key, so a host with two containers
pays a full KDF pass per device, while a typed passphrase is shared through the
keyring.

If askpass fails with "systemd-reply-password: No such file or directory", clevis
was built against a different systemd than the initrd's: it must use
`config.systemd.package`. To unlock by hand from initrd SSH, run
`clevis luks pass -d DEV -s SLOT | <initrd systemd>/lib/systemd/systemd-reply-password 1 <Socket= from the ask file>`.

## LUKS slots formatted on Odin

cryptsetup sizes argon2id by benchmarking the machine that runs `luksFormat`. A slot made on Odin for an ARM board
cost about 1 GiB and 19 s to unlock there. After any `luksFormat`, `luksAddKey` or `luksChangeKey` done on Odin for
a weaker host, retune the slot on the target with
`cryptsetup luksConvertKey --key-slot N --key-file - --pbkdf argon2id --pbkdf-memory 262144 <dev>`. The clevis slot
is pbkdf2 at a fixed cost and needs nothing.

## disko for an aarch64 host

`disko --flake .#<host>` on Odin runs the target's aarch64 `zpool` under emulation; the ZFS ioctl ABI is per
architecture, so it aborts after partitioning. Feed disko the layout as data instead, built with the repo's nixpkgs
so userland matches Odin's ZFS module:

```sh
nix eval --json .#nixosConfigurations.<host>.config.disko.devices \
  --apply '<recursively drop attrs whose name starts with "_">' > disko.json
printf '{ disko.devices = builtins.fromJSON (builtins.readFile ./disko.json); }\n' > disko.nix
sudo nix run --inputs-from . --override-input nixpkgs nixpkgs \
  github:nix-community/disko/<locked rev> -- --mode disko ./disko.nix
```

`--inputs-from` alone does not override disko's nixpkgs. A zapped table leaves old ZFS labels behind, so
`zpool labelclear -f` each new partition before `zpool create`.
