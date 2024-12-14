{ config, pkgs, ... }: 
{
    services.flatpak.packages = [ "flathub:app/com.borgbase.Vorta//stable" ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/System/Vorta" = {
                directories = [
                    ".var/app/com.borgbase.Vorta"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/com.borgbase.Vorta.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/exports/share/applications/com.borgbase.Vorta.desktop";
            };
        };
    };
}

