{ config, pkgs, ... }: 
{
    services.flatpak = {
        packages = [ "flathub:app/org.moneymanagerex.MMEX//stable" ];
        overrides."org.moneymanagerex.MMEX" = {
            filesystems = [
                "/Storage/Files/Documents"
            ];
        };
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Core/MoneyManager" = {
                directories = [
                    ".var/app/org.moneymanagerex.MMEX"
                    ".mmex"
                ];
                allowOther = true;
            };
        };
    };
}

