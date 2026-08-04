# Syncthing
#
# The device IDs, folder set and the settings that have to agree across peers
# come from the shared mesh module in 0-common. What is left here is
# Ragnarok-specific: where the data lives, and versioning.
#
# Versioning is the point of running Syncthing on this host at all. Everywhere
# else it is a sync mesh; here it is a second backup tier alongside borg, and
# the two fail differently. Borg snapshots on a schedule, so a file deleted and
# emptied between runs is only recoverable from the previous snapshot. Syncthing
# versioning catches the change itself -- the moment a peer propagates a delete
# or an overwrite, the old content is moved aside here rather than removed.
#
# Staggered rather than trashcan or simple:
#
#   trashcan  keeps one copy of a deleted file and nothing of an overwritten
#             one. Useless against a file that is edited wrongly and synced.
#   simple    keeps N versions regardless of age, so a noisy folder evicts the
#             history of a quiet one within a day.
#   staggered thins by age -- every version for an hour, hourly for a day, daily
#             for a month, weekly beyond that. Recovery is usually "how it was
#             last Tuesday", which is exactly the axis this thins along.
#
# maxAge = 0 means never delete by age. On a host whose entire job is holding
# other machines' data, and with the pool far larger than the synced set, the
# cost of keeping is lower than the cost of discovering a gap. Watch pool usage
# rather than assuming; `zfs list` on the data pool is the check.
#
# The versions live under .stversions inside each folder, so they land on the
# same dataset and are covered by the same snapshots and scrubs as the data.
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
        overrideDevices = true;
        overrideFolders = true;
    };

    syncthing-mesh = {
        self = "Ragnarok";

        folderOptions = {
            versioning = {
                type = "staggered";
                params = {
                    cleanInterval = "3600";
                    maxAge = "0";
                };
            };

            # Same reasoning as Heimdall: this is a slow disk on a small board,
            # so scanning is scheduled rather than continuous and the worker
            # pools are kept to one each.
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

    # Behind borg and the backup jobs. This host's reason to exist is receiving
    # backups; syncing is the secondary tier and should yield to it.
    systemd.services.syncthing.serviceConfig = {
        Nice = 15;
        IOSchedulingClass = "idle";
        IOWeight = 30;
        CPUWeight = 30;
    };
}
