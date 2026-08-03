{
    inputs,
    pkgs,
    ...
}:
{
    #imports = [
    #    (import "${inputs.mobile-nixos}/lib/configuration.nix" { device = "pine64-pinephone"; })
    #];

    nixpkgs.hostPlatform = "aarch64-linux";

    hardware = {
        enableRedistributableFirmware = true;
        firmware = [ (pkgs.callPackage "${inputs.mobile-nixos}/devices/pine64-pinephone/firmware" { }) ];
    };

    environment.systemPackages = [
        pkgs.firefox
        pkgs.thunderbird
        
    ];

    boot.kernelParams = [
        "console=tty0"
        "console=ttyS0,115200"
    ];

    hardware.deviceTree.name = "allwinner/sun50i-a64-pinephone-1.2.dtb";

    # megi's kernel is monolithic: the entire tree builds exactly two modules,
    # efivarfs and r8723bs. Everything else this phone needs is `=y`, including
    # MMC_SUNXI, MMC_BLOCK, EXT4_FS, VFAT_FS, the AXP803 drivers, the USB gadget
    # stack and INV_MPU6050_I2C. That is the postmarketOS approach and it is
    # correct for the hardware -- there is nothing to hotplug on a phone.
    #
    # So there is nothing to declare here. The previous list named
    # rtw88_8723cs (mainline's driver; megi uses RTL8723CS), ax88179_178a
    # (built in) and st_lsm6dsx (a sensor this phone does not have -- it is an
    # MPU6050), none of which exist as modules. modprobe failures on those are
    # very likely what the earlier "a few units failed to load" was.
    boot.kernelModules = [ ];

    # NixOS defaults this to true, which pulls in an x86 desktop list --
    # ahci, ata_piix, sata_nv, pata_marvell, nvme, tpm-tis, uhci_hcd,
    # hid_corsair and friends. nixpkgs' own aarch64 kernel builds those as
    # modules so nobody notices; megi's does not build them at all, and
    # makeModulesClosure runs with allowMissing = false, so the build dies with
    #
    #     root module: ahci
    #     modprobe: FATAL: Module ahci not found
    #
    # Nothing on that list exists on a PinePhone. The root filesystem is ZFS on
    # eMMC, and both the MMC controller and the block layer are built in, so the
    # initrd needs no storage modules of its own. ZFS itself is added by
    # boot.supportedFilesystems rather than by name.
    boot.initrd.includeDefaultModules = false;

    # There is no TPM in a PinePhone. boot.initrd.systemd.tpm2 defaults to true
    # and adds tpm-tis and tpm-crb to availableKernelModules, which megi's
    # kernel does not build, so makeModulesClosure fails the same way ahci did:
    #
    #     root module: tpm-crb
    #     modprobe: FATAL: Module tpm-crb not found
    #
    # nixpkgs already skips tpm-crb on riscv64 and armv7, but not on aarch64 --
    # reasonable, since most aarch64 machines running NixOS are servers that do
    # have one.
    #
    # Nothing here uses TPM anyway: the pool is unlocked by clevis against
    # Odin's tang server, or by passphrase.
    boot.initrd.systemd.tpm2.enable = false;
}
