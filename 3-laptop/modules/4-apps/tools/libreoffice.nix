{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/org.libreoffice.LibreOffice//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Tools/LibreOffice" = {
                directories = [
                    ".var/app/org.libreoffice.LibreOffice"
                ];
                allowOther = true;
            };
        };
    };
}

