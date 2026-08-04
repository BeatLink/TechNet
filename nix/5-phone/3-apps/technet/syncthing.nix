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
{ config, ... }:
{
    sops.secrets.syncthing_cert = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_key = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };

    syncthing-mesh = {
        self = "Thor";

        # Scheduled scans rather than continuous, and one worker each. This is
        # four slow cores on an SD card, and the phone has other things to do.
        folderOptions = {
            rescanIntervalS = 86400;
            fsWatcherEnabled = true;
            fsWatcherDelayS = 60;
            hashers = 1;
            copiers = 1;
        };
    };

    home-manager.users.beatlink = {
        services.syncthing = {
            enable = true;
            cert = config.sops.secrets.syncthing_cert.path;
            key = config.sops.secrets.syncthing_key.path;
            overrideDevices = true;
            overrideFolders = true;
            settings = config.syncthing-mesh.settings;
        };

        home.persistence."/Storage/Apps/TechNet/SyncThing" = {
            directories = [
                ".local/state/syncthing"
            ];
        };
    };
}
