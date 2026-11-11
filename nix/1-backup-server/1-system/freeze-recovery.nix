# Freeze Recovery ####################################################################################################################################
#
# Reboots the board when it freezes, and streams its kernel log and memory use to Heimdall so whatever froze it is still on record after the reboot.
#
{ lib, pkgs, ... }:
{
    config = lib.mkMerge [

        # Watchdog ###################################################################################################################################
        {
            systemd.settings.Manager.RuntimeWatchdogSec = "30s"; # The DesignWare timer's own period

            boot.kernel.sysctl = {
                "kernel.hung_task_panic" = 1;
                "kernel.softlockup_panic" = 1;
                "kernel.hardlockup_panic" = 1;
            };
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

        # Memory Trail ###############################################################################################################################
        {
            systemd.services.memory-trail = {
                description = "Log memory and swap use to the journal and Heimdall";
                wantedBy = [ "multi-user.target" ];
                path = [ pkgs.gawk ];
                serviceConfig = {
                    Restart = "always";
                    SyslogLevel = "debug"; # Below journald's console level, so the lines stay off the serial login screen
                };
                script = ''
                    swap_pages() { awk '$1 == "pswpin" { i = $2 } $1 == "pswpout" { o = $2 } END { print i, o }' /proc/vmstat; }
                    read -r last_in last_out < <(swap_pages)
                    while sleep 5; do
                        read -r now_in now_out < <(swap_pages)
                        memory=$(awk '{ kb[$1] = $2 } END {
                            printf "available %dM, swap used %dM", kb["MemAvailable:"] / 1024, (kb["SwapTotal:"] - kb["SwapFree:"]) / 1024
                        }' /proc/meminfo)
                        swapped="pages swapped in $((now_in - last_in)) out $((now_out - last_out))"
                        pressure=$(awk '{ split($2, avg, "="); printf " %s %s", $1, avg[2] }' /proc/pressure/memory)
                        line="$memory, $swapped, pressure$pressure"
                        echo "$line"
                        echo "memory-trail: $line" > /dev/udp/192.168.0.2/6666 || true
                        last_in=$now_in
                        last_out=$now_out
                    done
                '';
            };
        }
    ];
}
