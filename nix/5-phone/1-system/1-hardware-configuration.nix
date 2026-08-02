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

    # The sun4i USB phy and the musb controller are built into the kernel on this
    # platform rather than being modules, so they are not listed here.
    # Battery, charging and keyboard drivers live in 11-power.nix and
    # 12-keyboard.nix.
    boot.kernelModules = [
        "rtw88_8723cs" # Wifi Card
        "ax88179_178a" # USB Hub
        "st_lsm6dsx" # Accelerometer
    ];
}
