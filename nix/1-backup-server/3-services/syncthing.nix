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
            # Syncthing creates these directories itself but not their parents, so without the tmpfiles rules the first start dies on mkdir
            services.syncthing = {
                databaseDir = "/var/lib/syncthing-database";
                dataDir = "/Storage/Services/Syncthing/Data";
                configDir = "/Storage/Services/Syncthing/Config";
            };

            # The index is SQLite writing 4K pages, which the data pool's 1M recordsize and copies=2 turn into a megabyte read-modify-write done twice;
            # the root SSD's persistent dataset is 128K and copies=1, so the same page costs an eighth of the I/O and half the writes. Derived data, but
            # rebuilding it means rehashing every folder, so it is persisted rather than left on the wiped root.
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
        # A slow single-disk pool on a four-core board, so scanning is scheduled rather than continuous and the hasher and copier pools are kept to one.
        {
            syncthing-mesh.folderOptions = {
                rescanIntervalS = 86400;
                fsWatcherEnabled = true;
                fsWatcherDelayS = 60;
                hashers = 1;
                copiers = 1;
                pullerMaxPendingKiB = 16384;
                scanProgressIntervalS = -1;
                copyRangeMethod = "copy_file_range"; # Needs feature@block_cloning on the pool; falls back to standard copying without it
                caseSensitiveFS = true; # Data loss if the pool is ever rebuilt with casesensitivity=insensitive
            };

            services.syncthing.settings = lib.recursiveUpdate config.syncthing-mesh.settings {
                options = {
                    maxConcurrentIncomingRequestKiB = 32768;
                    progressUpdateIntervalS = -1;
                };
            };
        }

        # Resource Limits ############################################################################################################################
        # This host exists to receive backups, so syncing yields to them.
        {
            systemd.services.syncthing.serviceConfig = {
                # Contention-only, deliberately: Nice, the weights and the idle I/O class cost nothing while the board is quiet and yield the moment
                # a backup wants the CPU. A CPUQuota was here and had to go -- half a core throttled syncthing 32593 times in under an hour, and a
                # TLS handshake that cannot be scheduled inside the peer's timeout drops as EOF, so the mesh lost its connections to this host.
                Nice = 15;
                IOSchedulingClass = "idle"; # ZFS issues pool I/O from its own threads, so the I/O priorities only reach what Syncthing does off-pool
                IOWeight = 30;
                CPUWeight = 30;

            };

            # A ceiling the kernel enforces is the wrong tool here. MemoryHigh at 160M held syncthing at its watermark and reclaimed against it 18
            # times while 576M of the host sat free, and a TLS handshake starved of either CPU or memory drops as EOF -- Heimdall lost the mesh
            # connection to this host entirely until both ceilings came off, and it re-established within seconds of that.
            #
            # GOMEMLIMIT is the exception worth keeping: it is a target the collector aims at rather than a wall, so a heap that genuinely needs more
            # gets it and only pays extra GC. 384MiB leaves room for a full index rebuild of the backup tree, which 140MiB did not.
            systemd.services.syncthing.environment.GOMEMLIMIT = "384MiB";
        }
    ];
}
