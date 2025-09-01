{
    nixpkgs.config.permittedInsecurePackages = [
        "ventoy-gtk3-1.1.05"
    ];

    home-manager.users.beatlink = { pkgs, ... }: {
        nixpkgs.config.permittedInsecurePackages = [
            "ventoy-gtk3-1.1.05"
        ];
        home = {
            packages =  [ pkgs.ventoy-full-gtk ];
            persistence."/Storage/Apps/Tools/Ventoy" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

