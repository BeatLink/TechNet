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
# The versions live under .syncthing/versions inside each folder, so they land
# on the same dataset and are covered by the same snapshots and scrubs as the
# data.
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

    # syncthing.ragnarok.lan, served by nginx here and proxied to loopback, so
    # the GUI survives Heimdall or WireGuard being down -- which is when this
    # host's backups are most likely to be what you need.
    technet.vhosts.syncthing = {
        port = 8384;
        # Reachable from other machines too, via the CNAME on Heimdall.
        openFirewall = true;
    };

    # Syncthing runs as beatlink and creates its own Database, Data and Config
    # directories, but it cannot create the parents: /Storage/Services came out
    # root-owned here, so the first start died with
    #
    #     Failed to ensure directory exists
    #       (error="mkdir /Storage/Services/Syncthing/Database: permission denied")
    #
    # Heimdall has the same undeclared dependency and only works because those
    # directories were made by hand in April. Declaring them is what makes this
    # reproducible on a host that has never run it.
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

    services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        cert = config.sops.secrets.syncthing_cert.path;
        key = config.sops.secrets.syncthing_key.path;
        guiAddress = "127.0.0.1:8384";
        guiPasswordFile = config.sops.secrets.syncthing_gui_password.path;
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
    #
    # CPUQuota is the addition that does something. Nice and CPUWeight only
    # decide who wins a contest for the CPU, and the lesson from Thor was that on
    # an otherwise idle box there is no contest to win: a Nice 19 Syncthing still
    # took every core it could reach. A quota is an absolute ceiling whether or
    # not anything else wants the time, which is what keeps a first sync from
    # being the whole machine. 50% is two of four cores.
    #
    # Worth being honest about what it does not fix. The load average here was 41
    # on four cores, and most of that is tasks blocked on the disk rather than
    # tasks wanting the CPU, so capping CPU moves that number far less than it
    # looks like it should. The disk side is the queue depths in
    # 1-system/4-data-drive.nix and the folder concurrency above -- and on this
    # host that side has a floor, because the pool is a single shingled drive
    # whose write stalls are a property of the media rather than of scheduling.
    #
    # The IOSchedulingClass and IOWeight here reach the block layer without
    # Syncthing's priority attached, because ZFS issues the actual I/O from its
    # own threads. They are kept because they still apply to whatever Syncthing
    # does outside the pool, not because they pace the sync.
    systemd.services.syncthing.serviceConfig = {
        Nice = 15;
        IOSchedulingClass = "idle";
        IOWeight = 30;
        CPUWeight = 30;
        CPUQuota = "50%";
    };
}
