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
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_key = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_gui_password = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };

    syncthing-mesh.self = "Odin";

    # The GUI is reached at syncthing-odin.heimdall.technet, proxied by Heimdall's nginx over WireGuard.
    networking.firewall.interfaces."wireguard0".allowedTCPPorts = [ 8384 ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                syncthingtray-minimal
                libxcb
            ];
            # The fake graphical-session target fires before Cinnamon imports DISPLAY into the user manager, so the
            # first start finds no display, and Qt aborts rather than waiting once no platform plugin loads.
            systemd.user.services.syncthingtray = {
                Unit = {
                    StartLimitIntervalSec = 120;
                    StartLimitBurst = 10;
                };
                Service = {
                    Restart = "on-failure";
                    RestartSec = 5;
                };
            };

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
                guiAddress = "0.0.0.0:8384";
                guiCredentials = {
                    username = "beatlink";
                    passwordFile = config.sops.secrets.syncthing_gui_password.path;
                };
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
