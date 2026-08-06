# Hardware Configuration ###############
{
    inputs,
    pkgs,
    ...
}:
{
    nixpkgs.hostPlatform = "aarch64-linux";

    # Firmware -----------------------------------
    hardware = {
        enableRedistributableFirmware = true;
        firmware = [ (pkgs.callPackage "${inputs.mobile-nixos}/devices/pine64-pinephone/firmware" { }) ];
        deviceTree.name = "allwinner/sun50i-a64-pinephone-1.2.dtb";
    };

    # Boot ---------------------------------------
    boot = {
        kernelParams = [
            "console=tty0"
            "console=ttyS0,115200"
        ];

        kernelModules = [ ];

        initrd = {
            includeDefaultModules = false;
            systemd.tpm2.enable = false;
        };
    };
}
