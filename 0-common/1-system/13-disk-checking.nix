{
    config,
    pkgs,
    lib,
    ...
}:

with lib;

let
    cfg = config.services.diskZfsHealth;
in
{
    options.services.diskZfsHealth = {
        enable = mkEnableOption "Enable Disk & ZFS Health Checks";

        uptimeKumaUrl = mkOption {
            type = types.str;
            description = "Uptime Kuma push URL for disk and ZFS health reports";
        };

        # New option: interval for the timer
        checkInterval = mkOption {
            type = types.str;
            default = "daily";
            description = ''
                Systemd OnCalendar string or timer interval for running the health check.
                Examples: "daily", "hourly", "weekly", "OnCalendar=*-*-* 06:00:00", "30min", "1h".
            '';
        };
    };

    config = mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
            smartmontools
            zfs
            curl
            gawk
            util-linux
        ];

        # Health check service
        systemd.services.disk-zfs-health = {
            description = "Disk & ZFS Health Check";
            serviceConfig = {
                Type = "oneshot";
                ExecStart = ''${pkgs.bash}/bin/bash -e /etc/nixos/disk-zfs-health.sh'';
            };
            wantedBy = [ "multi-user.target" ];
        };

        # Health check timer
        systemd.timers.disk-zfs-health = {
            description = "Disk & ZFS Health Check Timer";
            timerConfig =
                if builtins.match "^[0-9]+[smhd]?$" cfg.checkInterval != null then
                    {
                        OnUnitActiveSec = cfg.checkInterval;
                        Persistent = true;
                    }
                else
                    {
                        OnCalendar = cfg.checkInterval;
                        Persistent = true;
                    };
            wantedBy = [ "timers.target" ];
        };

        # Deploy script
        environment.etc."nixos/disk-zfs-health.sh".text = ''
            #!${pkgs.bash}/bin/bash
            UPTIME_KUMA_URL="${cfg.uptimeKumaUrl}"

            STATUS="Up"

            check_smart() {
                local disk="$1"
                local result
                result=$(${pkgs.smartmontools}/bin/smartctl -H "$disk" 2>/dev/null | grep -i 'result')
                if echo "$result" | grep -iq "fail"; then
                    STATUS="Down"
                fi
                echo "$disk: $result"
            }

            check_zfs() {
                if ! command -v ${pkgs.zfs}/bin/zpool >/dev/null 2>&1; then
                    echo "ZFS not installed."
                    return
                fi
                ${pkgs.zfs}/bin/zpool status | while read -r line; do
                    echo "$line"
                    if echo "$line" | grep -Eiq "DEGRADED|FAULTED|OFFLINE|UNAVAIL"; then
                        STATUS="Down"
                    fi
                done
            }

            DISKS=$(${pkgs.util-linux}/bin/lsblk -dn -o NAME,TYPE | ${pkgs.gawk}/bin/awk '$2=="disk"{print "/dev/"$1}')

            echo "Disk SMART checks:"
            for disk in $DISKS; do
                check_smart "$disk"
            done

            echo -e "\nZFS Pools Status:"
            check_zfs

            # Send simple GET request to Uptime Kuma
            curl -s "$UPTIME_KUMA_URL"

            echo "Report sent to Uptime Kuma. Status: $STATUS"
        '';
    };
}
