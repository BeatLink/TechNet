# Disk Health Monitoring  ##########################################################################################################################################
#
{
    config,
    pkgs,
    lib,
    ...
}:

with lib;

let
    cfg = config.services.disk-health-monitor;
in
{
    options.services.disk-health-monitor = {
        enable = mkEnableOption "Enable disk SMART and ZFS health monitoring for Uptime Kuma";

        baseUrl = mkOption {
            type = types.str;
            example = "https://my.uptime.kuma.server/api/push";
            description = "Base Uptime Kuma push URL (without the monitor-specific endpoint).";
        };

        endpoint = mkOption {
            type = types.str;
            example = "abc123";
            description = "Uptime Kuma monitor endpoint (appended to baseUrl).";
        };

        interval = mkOption {
            type = types.str;
            default = "1h";
            example = "30m";
            description = ''
                How often to run the disk health monitor.  
                Accepts systemd time spans (e.g. "5m", "30s", "1h").
            '';
        };
    };

    config = mkIf cfg.enable {
        systemd.services.disk-health-monitor = {
            description = "Disk & ZFS Health Monitor for Uptime Kuma";
            serviceConfig = {
                Type = "oneshot";
                ExecStart =
                    let
                        script = pkgs.writeShellScript "disk-health-monitor.sh" ''
                            #!${pkgs.bash}/bin/bash
                            set -eu

                            log() {
                                # Send logs to systemd journal
                                echo "$1" | ${pkgs.systemd}/bin/systemd-cat -t disk-health-monitor
                            }

                            push_url="${cfg.baseUrl}/${cfg.endpoint}"
                            status="up"
                            message="Disk and ZFS health OK"

                            check_smart() {
                                local disk="$1"
                                local transport
                                transport=$(${pkgs.util-linux}/bin/lsblk -no TRAN "$disk" 2> >(${pkgs.systemd}/bin/systemd-cat -t disk-health-monitor -p err) || echo "")

                                if [[ "$transport" == "usb" ]]; then
                                    result=$(${pkgs.smartmontools}/bin/smartctl -H -d sat "$disk" \
                                        2> >(${pkgs.systemd}/bin/systemd-cat -t disk-health-monitor -p err) || true)
                                else
                                    result=$(${pkgs.smartmontools}/bin/smartctl -H "$disk" \
                                        2> >(${pkgs.systemd}/bin/systemd-cat -t disk-health-monitor -p err) || true)
                                fi

                                if echo "$result" | grep -iq "FAIL"; then
                                    status="down"
                                    message="SMART failure on $disk: $result"
                                    log "SMART check failed for $disk"
                                else
                                    log "SMART check OK for $disk"
                                fi
                            }

                            check_zfs() {
                                if [ -x "${pkgs.zfs}/bin/zpool" ]; then
                                    while read -r line; do
                                        if echo "$line" | grep -Eiq "DEGRADED|FAULTED|OFFLINE|UNAVAIL"; then
                                            status="down"
                                            message="ZFS pool issue: $line"
                                            log "ZFS issue detected: $line"
                                        fi
                                    done < <(${pkgs.zfs}/bin/zpool status \
                                        2> >(${pkgs.systemd}/bin/systemd-cat -t disk-health-monitor -p err))
                                    log "ZFS check completed"
                                fi
                            }

                            disks=$(${pkgs.util-linux}/bin/lsblk -dn -o NAME,TYPE \
                                2> >(${pkgs.systemd}/bin/systemd-cat -t disk-health-monitor -p err) \
                                | ${pkgs.gawk}/bin/awk '$2=="disk"{print "/dev/"$1}')

                            for d in $disks; do
                                check_smart "$d"
                            done

                            check_zfs

                            log "Final status: $status - $message"

                            ${pkgs.curl}/bin/curl \
                                --get \
                                --data-urlencode "status=$status" \
                                --data-urlencode "msg=$message" \
                                --silent \
                                "$push_url" \
                                > /dev/null
                        '';

                    in
                    script;
            };
        };

        systemd.timers.disk-health-monitor = {
            description = "Run Disk Health Monitor every ${cfg.interval}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnBootSec = "2m";
                OnUnitActiveSec = cfg.interval;
            };
        };
    };
}
