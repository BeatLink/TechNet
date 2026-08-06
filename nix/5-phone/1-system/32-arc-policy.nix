{ config, ... }:
{
    systemd.services.data-pool-cache-policy = {
        description = "Cache only metadata for the data pool, leaving the ARC to the apps";
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs-import.target" ];
        unitConfig.ConditionPathExists = "/Storage";
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        path = [ config.boot.zfs.package ];
        script = ''
            zfs set primarycache=metadata data-pool-${config.networking.hostName}/storage
        '';
    };
}
