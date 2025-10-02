{ pkgs, ... }:
{

    nixpkgs.config.permittedInsecurePackages = [
        "olm-3.2.16"
    ];

    environment.systemPackages = [ pkgs.chatty ];
}
