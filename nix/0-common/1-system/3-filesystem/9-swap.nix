{ config, lib, ... }:
let
    zvolSwaps = lib.filter (sw: lib.hasPrefix "/dev/zvol/" sw.device) config.swapDevices;
in
{
    systemd.services = lib.listToAttrs (
        map (
            sw:
            lib.nameValuePair "mkswap-${sw.deviceName}" {
                after = [ "zfs-volume-wait.service" ];
                requires = [ "zfs-volume-wait.service" ];
            }
        ) zvolSwaps
    );
}
