# Freeze Recovery ####################################################################################################################################
#
# Reboots the board when it freezes, and streams its kernel log and memory use to Heimdall so whatever froze it is still on record after the reboot.
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

        # Netconsole #################################################################################################################################
        {
            # Carries panics and oopses only: the console level stays at the command line's 3, because one level covers every console and a flood
            # of warnings printed to the 115200 baud serial one locks the board up hard enough to stop softdog's timer
            systemd.services.netconsole = {
                description = "Send kernel panics to the LAN";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                path = [
                    pkgs.gawk
                    pkgs.iproute2
                    pkgs.kmod
                ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                };
                script = ''
                    address=$(ip -4 -o addr show end0 | awk '{ print $4 }' | cut -d/ -f1)

                    # Broadcast, as the firmware's own console does, so the receiver needs no MAC address here.
                    modprobe netconsole netconsole="6666@$address/end0,6666@192.168.0.255/ff:ff:ff:ff:ff:ff"
                '';
            };
        }

        # Kernel Log Trail ###########################################################################################################################
        {
            # Everything below the console level reaches Heimdall from here instead, where a flood costs this process time and nothing else
            systemd.services.kernel-log-trail = {
                description = "Stream the kernel log to Heimdall";
                wantedBy = [ "multi-user.target" ];
                path = [ pkgs.util-linux ];
                serviceConfig = {
                    Restart = "always";
                    Nice = 10;
                };
                script = ''
                    dmesg --follow-new | while IFS= read -r line; do
                        echo "$line" > /dev/udp/192.168.0.2/6666 || true
                    done
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
