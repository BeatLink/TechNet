{
    config,
    lib,
    pkgs,
    ...
}:
{
    environment.systemPackages = with pkgs; [ variety ];
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home = {
                file.".config/autostart/variety.desktop".source =
                    "${pkgs.variety}/share/applications/variety.desktop";
                persistence."/Storage/Apps/System/Variety" = {
                    directories = [
                        ".config/variety"
                    ];

                };
            };
        };
}
