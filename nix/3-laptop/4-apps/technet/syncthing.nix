# Syncthing
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism.
#
# The device IDs, folder set and the settings that have to agree across peers come from the shared mesh module in 0-common; what is left
# here is Odin-specific -- the user service, the tray applet and where state persists.
#
{ config, inputs, ... }:
{
    sops.secrets.syncthing_cert = {
        sopsFile = "${inputs.self}/secrets/3-laptop/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_key = {
        sopsFile = "${inputs.self}/secrets/3-laptop/syncthing.yaml";
        owner = "beatlink";
    };

    syncthing-mesh.self = "Odin";

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                syncthingtray-minimal
                libxcb
            ];
            systemd.user.targets.tray = {
                Unit = {
                    Description = "Home Manager System Tray";
                    Requires = [ "graphical-session-pre.target" ];
                };
            };
            services.syncthing = {
                enable = true;
                tray = {
                    enable = true;
                    command = "syncthingtray --wait";
                };
                cert = config.sops.secrets.syncthing_cert.path;
                key = config.sops.secrets.syncthing_key.path;
                overrideDevices = true;
                overrideFolders = true;
                settings = config.syncthing-mesh.settings;
            };
            home = {
                persistence."/Storage/Apps/TechNet/SyncThing" = {
                    directories = [
                        ".local/state/syncthing"
                    ];
                    files = [
                        ".config/syncthingtray.ini"
                    ];

                };
            };
        };
}
