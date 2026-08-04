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

            # maxFolderConcurrency is the one that matters. Without it Syncthing
            # hashes every folder it has work for at once -- eight of them here,
            # on four 1.15GHz cores, which is what pinned the CPU. Both servers
            # already set it to 1; the phone needs it more than either.
            settings = lib.recursiveUpdate config.syncthing-mesh.settings {
                options = {
                    maxFolderConcurrency = 1;
                    maxConcurrentIncomingRequestKiB = 8192;
                    progressUpdateIntervalS = 60;
                };
            };
        };

        # Heimdall runs at Nice 10 and Ragnarok at 15; this is a phone with a
        # user looking at it, so it goes further. Syncing is never the thing in
        # front of you.
        #
        # A user unit rather than a system one, which is why the servers'
        # systemd.services.syncthing block does not apply here. Nice is the part
        # that always takes effect; CPUWeight and IOWeight depend on the user
        # manager having those controllers delegated, and are harmless if not.
        systemd.user.services.syncthing.Service = {
            Nice = 19;
            IOSchedulingClass = "idle";
            CPUWeight = 20;
            IOWeight = 20;
        };

        home.persistence."/Storage/Apps/TechNet/SyncThing" = {
            directories = [
                ".local/state/syncthing"
            ];
        };
    };
}
