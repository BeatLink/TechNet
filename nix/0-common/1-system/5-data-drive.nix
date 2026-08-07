# Data Drive
#
# Every TechNet host that has a data drive mounts it the same way: the
# `storage` dataset of that host's own `data-pool-<hostname>`, mounted at
# /Storage with `zfsutil` so ZFS supplies the mount options, `nofail` so a
# missing or still-locked pool does not strand the boot, and `neededForBoot`
# because persistence and service state live under it.
#
# Every host currently uses the defaults (beatlink-owned, 1777); the ownership
# options exist for a host that needs the mount point to belong to a service
# account instead. Prefer scoping ownership to the subdirectories that need it
# over changing the whole mount point -- see 1-backup-server's data drive module
# for that pattern.
#
# The pool itself is NOT created here -- it is made by hand or by a setup
# script during installation, unlike the root pool which disko lays down.
#

{
    config,
    lib,
    ...
}:
let
    cfg = config.technet.dataDrive;

    dataPool = lib.head (lib.splitString "/" cfg.dataset);

    # Named the same way 3-filesystem/1-disko.nix names it. If that ever stops
    # being the root pool, this ordering silently becomes a no-op rather than
    # breaking anything -- systemd ignores After= on a unit that does not exist.
    rootPool = "root-pool-${config.networking.hostName}";
in
{
    options.technet.dataDrive = {
        enable = lib.mkEnableOption "mounting this host's ZFS data pool at /Storage";

        mountPoint = lib.mkOption {
            type = lib.types.str;
            default = "/Storage";
            description = "Where the data dataset is mounted.";
        };

        dataset = lib.mkOption {
            type = lib.types.str;
            default = "data-pool-${config.networking.hostName}/storage";
            defaultText = lib.literalExpression ''"data-pool-\''${hostName}/storage"'';
            description = "ZFS dataset to mount. Defaults to this host's own data pool.";
        };

        user = lib.mkOption {
            type = lib.types.str;
            default = "beatlink";
            description = "Owner of the mount point.";
        };

        group = lib.mkOption {
            type = lib.types.str;
            default = "beatlink";
            description = "Group of the mount point.";
        };

        mode = lib.mkOption {
            type = lib.types.str;
            default = "1777";
            description = "Mode of the mount point.";
        };
    };

    config = lib.mkIf cfg.enable {
        fileSystems.${cfg.mountPoint} = {
            device = cfg.dataset;
            fsType = "zfs";
            options = [
                "zfsutil"
                "nofail"
            ];
            neededForBoot = true;
        };

        systemd.tmpfiles.settings."Storage".${cfg.mountPoint}.d = {
            inherit (cfg) user group mode;
        };

        # Prevents Import Racing
        boot.initrd.systemd.services."zfs-import-${dataPool}".after = [
            "zfs-import-${rootPool}.service"
        ];
    };
}
