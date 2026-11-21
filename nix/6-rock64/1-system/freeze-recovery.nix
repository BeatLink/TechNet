# Freeze Recovery ####################################################################################################################################
#
# Reboots the board when it freezes, and logs its memory use to the journal so whatever froze it is still on record after the reboot.
#
{ lib, pkgs, ... }:
{
    config = lib.mkMerge [

        # Watchdog ###################################################################################################################################
        {
            boot.initrd.kernelModules = [ "softdog" ];
            boot.kernelParams = [ "softdog.soft_margin=30" ];
            systemd.settings.Manager = {
                RuntimeWatchdogSec = "30s";
                WatchdogDevice = "/dev/watchdog0"; # softdog, only while the overlay below keeps the DesignWare timer from taking the number
            };

            # The DesignWare timer's reset hangs the board until a power cycle, so the kernel never gets a device for it
            hardware.deviceTree.overlays = [
                {
                    name = "no-hardware-watchdog";
                    dtsText = ''
                        /dts-v1/;
                        /plugin/;
                        / {
                            compatible = "pine64,rock64", "rockchip,rk3328";
                            fragment@0 {
                                target-path = "/watchdog@ff1a0000";
                                __overlay__ {
                                    status = "disabled";
                                };
                            };
                        };
                    '';
                }
            ];

            boot.kernel.sysctl = {
                "kernel.hung_task_panic" = 1;
                "kernel.softlockup_panic" = 1;
                "kernel.hardlockup_panic" = 1;
            };
        }

        # Memory Trail ###############################################################################################################################
        {
            systemd.services.memory-trail = {
                description = "Log memory and swap use to the journal";
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
                        echo "$memory, $swapped, pressure$pressure"
                        last_in=$now_in
                        last_out=$now_out
                    done
                '';
            };
        }
    ];
}
