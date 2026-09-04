# Hardware Configuration #############################################################################################################################
{
    inputs,
    pkgs,
    ...
}:
{
    nixpkgs.hostPlatform = "aarch64-linux";

    # Firmware ---------------------------------------------------------------------------------------------------------------------------------------
    hardware = {
        enableRedistributableFirmware = true;
        firmware = [ (pkgs.callPackage "${inputs.mobile-nixos}/devices/pine64-pinephone/firmware" { }) ];
        deviceTree.name = "allwinner/sun50i-a64-pinephone-1.2.dtb";
    };

    # Storage ----------------------------------------------------------------------------------------------------------------------------------------
    services.smartd.enable = false; # The eMMC and SD card expose no SMART, and smartd exits rather than start with zero devices registered

    # Boot -------------------------------------------------------------------------------------------------------------------------------------------
    boot = {
        kernelParams = [
            "console=tty0"
            "console=ttyS0,115200"
        ];

        kernelModules = [ ];

        initrd = {
            # Both false because megi's kernel builds neither set; true fails the build with modprobe: FATAL
            includeDefaultModules = false;
            systemd.tpm2.enable = false;
        };
    };
}
