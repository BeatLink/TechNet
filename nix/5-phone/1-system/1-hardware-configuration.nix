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

    boot.kernelModules = [
        "rtw88_8723cs" # Wifi Card
        "ax88179_178a" # USB Hub
        "st_lsm6dsx" # Accelerometer
        "typec_ucsi" # USB Port
        "axp20x_battery"
        "axp20x_usb_power"
        "sun4i_usb_phy"
        "typec"
        "pinephone_keyboard"
        "ip5xxx_power"
    ];
}
