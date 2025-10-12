{ pkgs, ... }:
{

    services.boinc = {
        enable = true;
        extraEnvPackages = [
            pkgs.docker
        ];
    };
    environment.persistence."/Storage/System/BOINC" = {
        directories = [
            {
                directory = "/var/lib/boinc/";
                user = "boinc";
                group = "boinc";
                mode = "u=rwx,g=rwx,o=";
            }
        ];
    };
    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Tools/BOINC-Manager" = {
                directories = [
                    ".local/share/boincmgr"
                    ".cache/boincmgr"
                    ".nv"
                ];
                files = [
                    ".BOINC Manager"
                ];
                allowOther = true;
            };
        };
    };
}
