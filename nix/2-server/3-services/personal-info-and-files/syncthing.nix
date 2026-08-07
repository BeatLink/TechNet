# Syncthing
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism
#
# The device IDs, folder set and the settings that have to agree across peers come from the shared mesh module in 0-common; what is left
# here is Heimdall-specific -- where the data lives, the web UI, and the tuning that exists because this host's storage is a spinning
# mirror.
#
{ config, lib, pkgs, inputs, ... }:
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
    services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        cert = config.sops.secrets.syncthing_cert.path;
        key = config.sops.secrets.syncthing_key.path;
        user = "beatlink";
        group = "beatlink";
        databaseDir = "/Storage/Services/Syncthing/Database";
        dataDir = "/Storage/Services/Syncthing/Data";
        configDir = "/Storage/Services/Syncthing/Config";
        guiPasswordFile = config.sops.secrets.syncthing_gui_password.path;
        overrideDevices = true;
        overrideFolders = true;
    };

    syncthing-mesh = {
        self = "Heimdall";
        folderOptions = {
            rescanIntervalS = 86400;
            fsWatcherEnabled = true;
            fsWatcherDelayS = 60;
            hashers = 1;
            copiers = 1;
        };
    };

    services.syncthing.settings = lib.recursiveUpdate config.syncthing-mesh.settings {
        options = {
           maxFolderConcurrency = 1;
            maxConcurrentIncomingRequestKiB = 32768;
            progressUpdateIntervalS = 30;
        };
        gui = {
            user = "beatlink";
            insecureSkipHostcheck = true;
        };
    };

    systemd.services.syncthing.serviceConfig = {
        Nice = 10;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 6;
        IOWeight = 50;
        CPUWeight = 50;
    };

    nginx-vhosts = {
        syncthing = {
            domain = "syncthing.heimdall.technet";
            port = 8384;
        };
        syncthing-odin = {
            domain = "syncthing-odin.heimdall.technet";
            host = "10.100.100.2";
            port = 8384;
        };
        syncthing-thor = {
            domain = "syncthing-thor.heimdall.technet";
            host = "10.100.100.4";
            port = 8384;
        };
    };

    systemd.services.syncthing-vigil-api-key = {
        description = "Extract Syncthing's API key for Vigil";
        after = [ "syncthing-init.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
            ${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' \
                /Storage/Services/Syncthing/Config/config.xml \
                > /Storage/Services/Syncthing/Config/.vigil-api-key.new
            chown vigil-access:vigil-access /Storage/Services/Syncthing/Config/.vigil-api-key.new
            chmod 0400 /Storage/Services/Syncthing/Config/.vigil-api-key.new
            mv -f /Storage/Services/Syncthing/Config/.vigil-api-key.new \
                /Storage/Services/Syncthing/Config/vigil-api-key
        '';
    };

    systemd.timers.syncthing-vigil-api-key = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "1m";
            OnUnitActiveSec = "1h";
        };
    };
}
