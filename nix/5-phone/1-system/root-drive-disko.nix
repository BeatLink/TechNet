# Root Drive #########################################################################################################################################
#
# btrfs subvolumes inside a LUKS container rather than the fleet's ZFS pool. The A53 has aes and pmull but OpenZFS carries its own crypto and never
# calls the kernel crypto API, so its AES-GCM runs as generic C; dm-crypt is GPL kernel code and does reach the instructions. Measured here, MB/s
# write/read: ZFS gcm 21.8/23.8, LUKS aes-xts + btrfs 91.4/195.9. Cold reads out of an encrypted /nix are what makes apps slow to launch.
#
# The SD card is still a ZFS pool, so hostId and the ZFS module stay.
#

{
    technet.storage.backend = "btrfs-luks";

    networking.hostId = "aef23b78";
    disko.devices.disk.root-drive.device = "/dev/disk/by-id/mmc-ASTCXX_0xd1002721";
}
