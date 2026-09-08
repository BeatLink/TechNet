{
    technet.secrets.directory = "2-server";
    technet.waypipe.serve = true;

    imports = [
        ./1-system
        ./3-services
        ./4-apps
        ./overlays.nix
    ];
}
