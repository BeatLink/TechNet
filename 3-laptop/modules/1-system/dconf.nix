{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.dconfImports;
in
{
  options.dconfImports = mkOption {
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

  config = mkMerge (mapAttrsToList (name: item:
    {
      systemd.user.services."${name}" = {
        Unit = {
          Description = "Load dconf settings into ${item.path}";
        };
        Service = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.dconf}/bin/dconf load ${item.path} < ${item.source}'";
          Type = "oneshot";
          RemainOnExit = true;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    }
  ) cfg) // {
    # Ensure dconf is installed
    home.packages = [ pkgs.dconf ];
  };
}
