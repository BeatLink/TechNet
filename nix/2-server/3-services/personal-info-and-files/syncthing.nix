# Syncthing
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism
#
{ config, lib, pkgs, inputs, ... }:
{
    sops.secrets.syncthing_cert = {
        sopsFile = "${inputs.self}/secrets/2-server/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_key = {
        sopsFile = "${inputs.self}/secrets/2-server/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_gui_password = {
        sopsFile = "${inputs.self}/secrets/2-server/syncthing.yaml";
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
        settings = {
            options = {
                urAccepted = -1;
                relaysEnabled = false;
                globalAnnounceEnabled = false;
                natEnabled = false;

                # Scanning is what makes syncthing expensive on this box: with
                # maxFolderConcurrency unlimited, all 9 folders can walk /Storage
                # simultaneously, and on a HDD mirror that is a seek storm rather
                # than 9x the throughput. Serialising to one folder at a time
                # costs little in latency (the filesystem watcher below is what
                # actually picks up changes) and keeps the pool responsive.
                maxFolderConcurrency = 1;

                # Cap the write side too, so a burst of incoming files from a
                # peer cannot saturate the mirror on its own.
                maxConcurrentIncomingRequestKiB = 32768;
                progressUpdateIntervalS = 30;
            };
            gui = {
                user = "beatlink";
                insecureSkipHostcheck = true;
            };
            devices = {
                Odin = {
                    addresses = [
                        "tcp://odin.lan:22000"
                        "tcp://odin.technet:22000"
                    ];
                    id = "CSIQ7OW-6MP3FSB-OBDABEA-S53TWYT-N2EFGT6-4FMUV7R-HMXLOF5-GLIW7AD";
                    numConnections = 8;
                };
                Thor = {
                    addresses = [
                        "tcp://thorx.technet:22000"
                        "tcp://thorx.lan:22000"
                    ];
                    id = "AGVZ3DQ-LX5CBXY-G6NKD4E-HOW7QNG-KAGSVOY-KRBUABG-BCDNEPU-SHJF4Q4";
                    numConnections = 8;
                };
            };
            # Every folder gets the same scan policy, layered on here rather than
            # repeated nine times. Per-folder keys below still win, since the
            # folder's own attrs are merged over these.
            #
            # rescanIntervalS is raised from the 1h default to 24h: a periodic
            # rescan re-stats every file in the tree, which is the single most
            # expensive thing syncthing does on spinning disks. It is only a
            # safety net for changes the watcher misses, so it does not need to
            # run hourly. fsWatcherEnabled is what actually detects edits, and it
            # is near-free — inotify pushes changes instead of syncthing walking
            # the tree to find them. The watcher delay batches a burst of writes
            # into one scan rather than one per file.
            folders = lib.mapAttrs (_: folder: {
                rescanIntervalS = 86400;
                fsWatcherEnabled = true;
                fsWatcherDelayS = 60;
                # Bound the per-folder worker pools. At 0 syncthing sizes hashers
                # by CPU count, which on 4 cores means 4 threads seeking the same
                # mirror at once; 1 hasher keeps reads sequential enough for the
                # drives to stay useful to everything else.
                hashers = 1;
                copiers = 1;

                # Sync permission bits. This works because every writer into
                # these trees runs as beatlink -- qbittorrent under Downloads and
                # openbooks under eBooks are both configured with user/group
                # beatlink -- so syncthing owns every file it needs to chmod.
                # If a service is ever moved back to its own account, chmod is
                # owner-restricted and that folder will stall with "handling dir
                # (setting permissions): chmod ...: operation not permitted".
                ignorePerms = false;
            } // folder) {
                "/Storage/Files/Documents" = {
                    label = "Documents";
                    id = "hz0k1-egjw9";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/Downloads" = {
                    label = "Downloads";
                    id = "unmbe-b2iab";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/eBooks" = {
                    label = "eBooks";
                    id = "kj0id-3vcea";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/Music" = {
                    label = "Music";
                    id = "8g86n-1309l";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/Pictures" = {
                    label = "Pictures";
                    id = "ta09s-b2u0y";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/Projects" = {
                    label = "Projects";
                    id = "xjtvv-cyqwv";
                    devices = [
                        "Odin"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/Sounds" = {
                    label = "Sounds";
                    id = "kae2q-5740v";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
                "/Storage/Files/Videos" = {
                    label = "Videos";
                    id = "4kqye-6dosm";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                };
            };
        };
    };
    # Syncthing's rescans and transfers walk the whole of /Storage and, on a
    # 2-disk HDD mirror, contend directly with borgmatic and with interactive
    # reads. Held at best-effort/6 rather than idle: unlike a backup, sync is
    # semi-interactive and a change should still propagate promptly, so it
    # yields to foreground work without being starved outright by it.
    # Requires BFQ on the data disks to take effect — see 2-data-drive.nix.
    systemd.services.syncthing.serviceConfig = {
        Nice = 10;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 6;
        IOWeight = 50;
        CPUWeight = 50;
    };

    nginx-vhosts.syncthing = {
        domain = "syncthing.heimdall.technet";
        port = 8384;
    };

    # Syncthing's REST API key lives only inside config.xml (owned
    # beatlink:beatlink, mode 0600, alongside the TLS key) — there is no
    # separate credential to hand Vigil. Rather than widening vigil-access's
    # sudo scope to read that whole file (which would also expose the TLS
    # private key) or adding either account to the other's group, this runs
    # as root (root can read any file regardless of group) and writes out
    # just the <apikey> value, owned vigil-access:vigil-access, mode 0400.
    # Re-run periodically (not just at boot) so a GUI-triggered API key
    # regeneration is picked up without a reboot.
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
