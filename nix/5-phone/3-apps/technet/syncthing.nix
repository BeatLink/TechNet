# Syncthing
#
# The device IDs, folder set and the settings that have to agree across peers
# come from the shared mesh module in 0-common. What is left here is
# Thor-specific.
#
# No tray applet. Odin runs syncthingtray, which is Qt and desktop-shaped; there
# is no adaptive Syncthing manager packaged for a phone. The web UI on
# localhost:8384 is the practical front end here, and with the mesh declared in
# Nix there is little to drive by hand anyway -- devices and folders are
# overridden from config on every start.
#
# Note this host is `Thor`, the PinePhone at thor.technet. The Android phone is
# `ThorX` at thorx.technet, a separate peer configured on the device itself. The
# mesh used to call the Android one Thor, which collided with this host's
# networking.hostName.
#
# State persists to the card like the other apps. Syncthing keeps its database
# under .local/state/syncthing, which is regenerable but expensive to rebuild --
# losing it means rehashing every synced file on a phone.
#
{ config, lib, ... }:
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

    networking.firewall.interfaces."wireguard0".allowedTCPPorts = [ 8384 ];

    # syncthing.thor.lan, served by nginx on this phone and proxied to loopback.
    # Not routed through Heimdall on purpose: a request from the phone to a
    # process on the phone should not leave over WireGuard and come back.
    technet.vhosts.syncthing = {
        port = 8384;
        # Reachable from other machines too, via the CNAME on Heimdall.
        openFirewall = true;
    };

    syncthing-mesh.self = "Thor";

    home-manager.users.beatlink = {
        services.syncthing = {
            enable = true;
            cert = config.sops.secrets.syncthing_cert.path;
            key = config.sops.secrets.syncthing_key.path;
            guiAddress = "0.0.0.0:8384";
            guiCredentials = {
                username = "beatlink";
                passwordFile = config.sops.secrets.syncthing_gui_password.path;
            };
            overrideDevices = true;
            overrideFolders = true;
            # Stated as defaults rather than dropped: the module PATCHes /rest/config/options, so an omitted key keeps whatever is already on disk.
            settings = lib.recursiveUpdate config.syncthing-mesh.settings {
                options = {
                    maxFolderConcurrency = 0;
                    maxConcurrentIncomingRequestKiB = 0;
                    maxSendKbps = 0;
                    maxRecvKbps = 0;
                    limitBandwidthInLan = false;
                    progressUpdateIntervalS = 5;
                };
            };
        };

        home.persistence."/Storage/Apps/TechNet/SyncThing" = {
            directories = [
                ".local/state/syncthing"
            ];
        };
    };
}
