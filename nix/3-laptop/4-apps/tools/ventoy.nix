{
    nixpkgs.config.permittedInsecurePackages = [
        "ventoy-gtk3-1.1.05"
    ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ pkgs.ventoy-full-gtk ];
                persistence."/Storage/Apps/Tools/Ventoy" = {
                    directories = [
                    ];

                };
            };
        };
}
