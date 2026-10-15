# Freeze Recovery ####################################################################################################################################
#
# Reboots the board when it freezes, and streams its kernel log to Heimdall so whatever froze it is still on record after the reboot.
#
{ lib, pkgs, ... }:
{
    config = lib.mkMerge [

        # Watchdog ###################################################################################################################################
        {
            systemd.settings.Manager.RuntimeWatchdogSec = "30s"; # The DesignWare timer's own period
        }

        # Netconsole #################################################################################################################################
        {
            systemd.services.netconsole = {
                description = "Stream the kernel log to the LAN";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                path = [
                    pkgs.gawk
                    pkgs.iproute2
                    pkgs.kmod
                    pkgs.util-linux
                ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                };
                script = ''
                    address=$(ip -4 -o addr show end0 | awk '{ print $4 }' | cut -d/ -f1)

                    # Broadcast, as the firmware's own console does, so the receiver needs no MAC address here.
                    modprobe netconsole netconsole="6666@$address/end0,6666@192.168.0.255/ff:ff:ff:ff:ff:ff"

                    # The command line's loglevel=3 keeps hung-task and USB reset messages off every console, this one included.
                    dmesg --console-level info
                '';
            };
        }
    ];
}
