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

                            push_url="${cfg.baseUrl}/${cfg.endpoint}"
                            status="up"
                            message="Disk and ZFS health OK"

                            check_smart() {
                              local disk="$1"
                              local result
                              result=$(${pkgs.smartmontools}/bin/smartctl -H "$disk" 2>/dev/null | grep -iE "PASSED|FAILED" || true)
                              if echo "$result" | grep -iq "fail"; then
                                status="down"
                                message="SMART failure on $disk: $result"
                              fi
                            }

                            check_zfs() {
                              if [ -x "${pkgs.zfs}/bin/zpool" ]; then
                                while read -r line; do
                                  if echo "$line" | grep -Eiq "DEGRADED|FAULTED|OFFLINE|UNAVAIL"; then
                                    status="down"
                                    message="ZFS pool issue: $line"
                                  fi
                                done < <(${pkgs.zfs}/bin/zpool status)
                              fi
                            }

                            disks=$(${pkgs.util-linux}/bin/lsblk -dn -o NAME,TYPE | ${pkgs.gawk}/bin/awk '$2=="disk"{print "/dev/"$1}')

                            for d in $disks; do
                              check_smart "$d"
                            done

                            check_zfs

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
