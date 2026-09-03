# Syncthing ##########################################################################################################################################
#
# Ragnarok's leg of the sync mesh. Device IDs, folders and the settings that must agree across peers come from the shared module in 0-common; what is
# here is where the data lives, versioning, and the ceilings that keep syncing behind the backup jobs.
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
                sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
                owner = "beatlink";
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
            # Syncthing creates these three directories itself but not their parents, so without the tmpfiles rules the first start dies on mkdir
            services.syncthing = {
                databaseDir = "/Storage/Services/Syncthing/Database";
                dataDir = "/Storage/Services/Syncthing/Data";
                configDir = "/Storage/Services/Syncthing/Config";
            };

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
        # syncthing.ragnarok.lan, served by nginx here and proxied to loopback, so the GUI survives Heimdall or WireGuard being down.
        {
            technet.vhosts.syncthing = {
                port = 8384;
                openFirewall = true; # Reachable from other machines too, via the CNAME on Heimdall
            };

            services.syncthing.guiAddress = "127.0.0.1:8384";
            services.syncthing.settings.gui = {
                user = "beatlink";
                insecureSkipHostcheck = true;
            };
        }

        # Versioning #################################################################################################################################
        {
            syncthing-mesh.folderOptions.versioning = {
                type = "staggered";
                params = {
                    cleanInterval = "3600";
                    maxAge = "0"; # Never expire a version by age; watch pool usage with zfs list rather than assuming it stays small
                };
            };
        }

        # Scan Throttling ############################################################################################################################
        # A slow single-disk pool on a four-core board, so scanning is scheduled rather than continuous and every worker pool is kept to one.
        {
            syncthing-mesh.folderOptions = {
                rescanIntervalS = 86400;
                fsWatcherEnabled = true;
                fsWatcherDelayS = 60;
                hashers = 1;
                copiers = 1;
            };

            services.syncthing.settings = lib.recursiveUpdate config.syncthing-mesh.settings {
                options = {
                    maxFolderConcurrency = 1;
                    maxConcurrentIncomingRequestKiB = 32768;
                    progressUpdateIntervalS = 30;
                };
            };
        }

        # Resource Limits ############################################################################################################################
        # This host exists to receive backups, so syncing yields to them.
        {
            systemd.services.syncthing.serviceConfig = {
                Nice = 15;
                IOSchedulingClass = "idle"; # ZFS issues pool I/O from its own threads, so the I/O priorities only reach what Syncthing does off-pool
                IOWeight = 30;
                CPUWeight = 30;
                CPUQuota = "50%"; # The only absolute ceiling here; on an otherwise idle board Nice and CPUWeight win every contest and cap nothing
            };
        }
    ];
}
