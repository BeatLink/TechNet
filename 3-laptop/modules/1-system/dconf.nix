{ config, lib, pkgs, ... }:

with lib;

let
    cfg = config.home-manager.users.beatlink.dconfImports;
in
{
    options = {
        home-manager.users.beatlink.dconfImports = mkOption {
            type = types.attrsOf (types.submodule {
                options = {
                    source = mkOption {
                        type = types.path;
                        description = "Path to the dconf dump file.";
                    };
                    path = mkOption {
                        type = types.str;
                        description = "Destination dconf path to load settings into (e.g., /org/blueman/).";
                    };
                };
            });
            default = { };
            description = "Set of dconf import services to load at startup. Attribute name becomes the service name.";
        };
    };


    config = {
        programs.dconf.enable = true;
    
        home-manager.users.beatlink = {
            home.packages = [ pkgs.dconf ];
            dconf.enable = true;  
            systemd.user.services."LoadDconfSettings" = {
                Unit = {
                    Description = "Load dconf settings";
                };
                Service = {
                    ExecStart = mapAttrsToList (name: value: "${pkgs.bash}/bin/bash -c '${pkgs.dconf}/bin/dconf load ${value.path} < ${value.source}'") cfg; 
                    Type = "oneshot";
                    RemainOnExit = true;
                };
                Install = {
                    WantedBy = [ "default.target" ];
                };
            };
        };

    };
}
