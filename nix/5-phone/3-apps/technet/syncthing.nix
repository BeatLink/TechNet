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
            guiAddress = "0.0.0.0:8384";
            guiCredentials = {
                username = "beatlink";
                passwordFile = config.sops.secrets.syncthing_gui_password.path;
            };
            overrideDevices = true;
            overrideFolders = true;

            # Turned down as far as it goes. Syncing here is explicitly allowed
            # to take the scenic route; the phone being responsive is worth more
            # than files arriving promptly.
            #
            # maxFolderConcurrency is the one that mattered most. Without it
            # Syncthing hashes every folder it has work for at once -- eight of
            # them here, on four 1.15GHz cores, which is what pinned the CPU.
            settings = lib.recursiveUpdate config.syncthing-mesh.settings {
                options = {
                    # One folder at a time, and one request in flight.
                    maxFolderConcurrency = 1;
                    maxConcurrentIncomingRequestKiB = 2048;

                    # Bounds how much a single folder can queue up before it has
                    # to finish writing, which is what turns a burst of pulls
                    # into a steady trickle on a card that hates bursts.
                    pullerMaxPendingKiB = 2048;

                    # Rate limits, applied to the LAN as well -- without
                    # limitBandwidthInLan the caps are ignored between local
                    # peers, which is every peer that matters here. 2MB/s is
                    # well under what the card sustains, so the transfer itself
                    # stops being the thing competing for IO.
                    maxSendKbps = 2048;
                    maxRecvKbps = 2048;
                    limitBandwidthInLan = true;

                    progressUpdateIntervalS = 60;
                };
            };
        };

        # Heimdall runs at Nice 10 and Ragnarok at 15; this is a phone with a
        # user looking at it, so it goes further. Syncing is never the thing in
        # front of you.
        #
        # A user unit rather than a system one, which is why the servers'
        # systemd.services.syncthing block does not apply here.
        #
        # CPUQuota is the one that actually bounds it. Nice and CPUWeight only
        # decide who wins a contest for the CPU -- with three cores otherwise
        # idle, a Nice 19 process still takes all three, which is exactly what
        # happened: syncthing sat at 97% while niced to 19. A quota is an
        # absolute ceiling whether or not anything else wants the time.
        #
        # 25% is one core's worth of four. Hashing the initial index will take
        # correspondingly longer, which is the trade being made deliberately.
        #
        # Checked before relying on it: the user slice has `cpu io memory pids`
        # delegated, so these apply rather than being silently ignored.
        systemd.user.services.syncthing.Service = {
            CPUQuota = "25%";
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
