{ pkgs, ... }:
{

    services.boinc = {
        enable = true;
        extraEnvPackages = [
            pkgs.docker
        ];
    };
    environment.persistence."/Storage/Apps/Tools/BOINC".directories = [ "/var/lib/boinc" ];
    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Tools/BOINC-Manager" = {
                directories = [
                    ".local/share/boincmgr"
                    ".cache/boincmgr"
                ];
                files = [
                    ".BOINC Manager"
                ];
                allowOther = true;
            };
        };
    };
}
