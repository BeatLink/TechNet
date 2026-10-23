# Syncthing
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism
#
# The device IDs, folder set and the settings that have to agree across peers come from the shared mesh module in 0-common; what is left
# here is Heimdall-specific -- where the data lives, the web UI, and the tuning that exists because this host's storage is a spinning
# mirror.
#
{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
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
        sopsFile = "${config.technet.secrets.commonPath}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_api_key = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        restartUnits = [
            "syncthing-api-key.service"
            "homepage-dashboard.service"
        ];
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
        UMask = "0002"; # Files it pulls into eBooks must stay writable by the other ebooks-group services (see 1-system/directories.nix); this applies to every folder it writes
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
        syncthing-ragnarok = {
            domain = "syncthing-ragnarok.heimdall.technet";
            host = "10.100.100.6";
            port = 8384;
        };
    };

    # Each peer's GUI also answers at syncthing.<host>.technet; the TLS certificate covers only *.heimdall.technet, so HTTPS on these names warns.
    services.nginx.virtualHosts.syncthing-odin.serverAliases = [ "syncthing.odin.technet" ];
    services.nginx.virtualHosts.syncthing-ragnarok.serverAliases = [ "syncthing.ragnarok.technet" ];
    services.pihole-ftl.settings.dns.cnameRecords = [
        "syncthing.odin.technet,heimdall.technet"
        "syncthing.ragnarok.technet,heimdall.technet"
    ];

    # Syncthing generates its own API key, so this swaps in the one from sops through the REST API whenever the two differ.
    systemd.services.syncthing-api-key = {
        description = "Apply Syncthing's API key from sops";
        after = [ "syncthing-init.service" ];
        wants = [ "syncthing-init.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RuntimeDirectory = "syncthing-api-key";
            RuntimeDirectoryMode = "0700";
        };
        # Keys travel through files in the runtime directory, never argv, so no process listing can show them.
        script = ''
            set -euo pipefail
            config_file=/Storage/Services/Syncthing/Config/config.xml
            new_key_file=${config.sops.secrets.syncthing_api_key.path}
            current_key=$(${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' "$config_file")
            if [ "$current_key" = "$(cat "$new_key_file")" ]; then
                exit 0
            fi
            printf 'X-API-Key: %s\n' "$current_key" > "$RUNTIME_DIRECTORY/headers"
            ${pkgs.jq}/bin/jq -n --rawfile key "$new_key_file" '{apiKey: ($key | rtrimstr("\n"))}' > "$RUNTIME_DIRECTORY/body"
            ${pkgs.curl}/bin/curl -sSf --retry 10 --retry-delay 3 --retry-all-errors -o /dev/null \
                -H @"$RUNTIME_DIRECTORY/headers" -H 'Content-Type: application/json' \
                -X PATCH --data @"$RUNTIME_DIRECTORY/body" http://127.0.0.1:8384/rest/config/gui
            systemctl start --no-block syncthing-x-monitor-api-key.service
        '';
    };

    systemd.services.syncthing-x-monitor-api-key = {
        description = "Extract Syncthing's API key for X-Monitor";
        after = [ "syncthing-init.service" ];
        serviceConfig.Type = "oneshot";
        # Written beside Config rather than inside it, since Syncthing holds Config at 0700 and no group can reach a file there.
        script = ''
            ${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' \
                /Storage/Services/Syncthing/Config/config.xml \
                > /Storage/Services/Syncthing/.x-monitor-api-key.new
            chown root:x-monitor-credentials /Storage/Services/Syncthing/.x-monitor-api-key.new
            chmod 0440 /Storage/Services/Syncthing/.x-monitor-api-key.new
            mv -f /Storage/Services/Syncthing/.x-monitor-api-key.new \
                /Storage/Services/Syncthing/x-monitor-api-key
        '';
    };

    systemd.timers.syncthing-x-monitor-api-key = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "1m";
            OnUnitActiveSec = "1h";
        };
    };
}
