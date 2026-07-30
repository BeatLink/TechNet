{
    technet.secrets.directory = "2-server";

    imports = [
        ./1-system
        ./3-services
        ./overlays.nix
    ];
}
