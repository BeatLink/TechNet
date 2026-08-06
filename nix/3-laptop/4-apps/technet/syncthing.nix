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

    networking.firewall.interfaces."wireguard0".allowedTCPPorts = [ 8384 ];

    # syncthing.odin.lan, served by nginx here and proxied to loopback, so the
    # name does not depend on Heimdall or WireGuard being up to reach a service
    # running on this machine.
    technet.vhosts.syncthing.port = 8384;

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
