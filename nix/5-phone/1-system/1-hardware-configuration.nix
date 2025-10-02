{
    inputs,
    config,
    pkgs,
    ...
}:
{

    #nix.nixPath = [ "mobile-nixos=${inputs.mobile-nixos}" ];

    #imports = [
    #    (import "/lib/configuration.nix" { device = "pine64-pinephone" })
    #];

    nixpkgs.hostPlatform = "aarch64-linux";

    hardware = {
        enableRedistributableFirmware = true;
        #firmware = [ config.mobile.device.firmware ];
    };

    environment.systemPackages = [
        pkgs.firefox
        pkgs.thunderbird
        (pkgs.callPackage "${inputs.mobile-nixos}/devices/pine64-pinephone/firmware" { })
    ];

    boot.kernelModules = [
        "rtw88_8723cs" # Wifi Card
        "ax88179_178a" # USB Hub
    ];
}
