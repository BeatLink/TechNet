# Syncthing ##########################################################################################################################################
#
# Ragnarok's leg of the sync mesh. Device IDs, folders and the settings that must agree across peers come from the shared module in 0-common; what is
# here is where the data lives, versioning, and scan scheduling tuned like Heimdall's.
# Versioning is the reason this host runs Syncthing at all: it is a second backup tier that catches a delete or overwrite as a peer propagates it,
# where borg would only have the previous scheduled snapshot.
#

{ config, lib, ... }:
{
    config = lib.mkMerge [

        # Secrets ####################################################################################################################################
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
                restartUnits = [ "syncthing-api-key.service" ];
            };

            services.syncthing = {
                cert = config.sops.secrets.syncthing_cert.path;
                key = config.sops.secrets.syncthing_key.path;
                guiPasswordFile = config.sops.secrets.syncthing_gui_password.path;
            };
        }

        # Sync Daemon ################################################################################################################################
        {
            services.syncthing = {
                enable = true;
                openDefaultPorts = true;
                user = "beatlink";
                group = "beatlink";
                overrideDevices = true;
                overrideFolders = true;
            };

            syncthing-mesh.self = "Ragnarok";

            # This host is a backup tier, not a source: receiveonly keeps a local deletion, such as clearing a file the scrub found corrupt, off the mesh
            syncthing-mesh.defaultType = "receiveonly";
        }

        # Storage Locations ##########################################################################################################################
        {
            # Syncthing creates these directories itself but not their parents, so without the tmpfiles rules the first start dies on mkdir
            services.syncthing = {
                databaseDir = "/var/lib/syncthing-database";
                dataDir = "/Storage/Services/Syncthing/Data";
                configDir = "/Storage/Services/Syncthing/Config";
            };

            # The index is SQLite rewriting scattered 4K pages, which the backup drive's dup profile writes twice and its shingled bands turn into
            # band rewrites; on the root SSD each page is one small write. Derived data, but rebuilding it means rehashing every folder, so it is
            # persisted rather than left on the wiped root.
            environment.persistence."/persistent".directories = [
                {
                    directory = "/var/lib/syncthing-database";
                    user = "beatlink";
                    group = "beatlink";
                    mode = "0700";
                }
            ];

            systemd.tmpfiles.settings."Syncthing" = {
                "/Storage/Services".d = {
                    user = "beatlink";
                    group = "beatlink";
                    mode = "0755";
                };
                "/Storage/Services/Syncthing".d = {
                    user = "beatlink";
                    group = "beatlink";
                    mode = "0755";
                };
            };
        }

        # Web Interface ##############################################################################################################################
        # syncthing-ragnarok.heimdall.technet, proxied by Heimdall's nginx over WireGuard.
        {
            services.syncthing.guiAddress = "0.0.0.0:8384"; # WireGuard and localhost only: wg0 is trusted here and the LAN interface has no 8384 rule
            services.syncthing.settings.gui = {
                user = "beatlink";
                insecureSkipHostcheck = true;
            };
        }

        # API Key ####################################################################################################################################
        {
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
                script = config.syncthing-mesh.applyApiKeyScript {
                    config_file = "${config.services.syncthing.configDir}/config.xml";
                    key_file = config.sops.secrets.syncthing_api_key.path;
                };
            };
        }

        # Versioning #################################################################################################################################
        {
            syncthing-mesh.folderOptions.versioning = {
                type = "staggered";
                params = {
                    cleanInterval = "3600";
                    maxAge = "0"; # Never expire a version by age; watch btrfs filesystem usage /Storage rather than assuming it stays small
                };
            };
        }

        # Scan Scheduling ############################################################################################################################
        # Matches Heimdall: the shingled backup drive is still the slow part, so scanning is scheduled and the hasher and copier pools kept to one.
        {
            syncthing-mesh.folderOptions = {
                rescanIntervalS = 86400;
                fsWatcherEnabled = true;
                fsWatcherDelayS = 60;
                hashers = 1;
                copiers = 1;
                copyRangeMethod = "copy_file_range"; # btrfs clones the extents instead of copying the data
                caseSensitiveFS = true; # btrfs has no case-insensitive mode, so Syncthing's case-conflict checks are skipped
            };

            services.syncthing.settings = lib.recursiveUpdate config.syncthing-mesh.settings {
                options = {
                    maxConcurrentIncomingRequestKiB = 32768;
                    progressUpdateIntervalS = 30;
                };
            };
        }

        # Scheduling Priority ########################################################################################################################
        {
            systemd.services.syncthing.serviceConfig = {
                Nice = 10;
                IOSchedulingClass = "best-effort";
                IOSchedulingPriority = 6;
                IOWeight = 50;
                CPUWeight = 50;
            };
        }
    ];
}
