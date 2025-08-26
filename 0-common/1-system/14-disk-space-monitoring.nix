{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.zpool-usage-monitor;
in {
  options.services.zpool-usage-monitor = {
    enable = mkEnableOption "Enable ZFS zpool usage monitoring for Uptime Kuma";

    baseUrl = mkOption {
      type = types.str;
      example = "https://my.uptime.kuma.server/api/push";
      description = "Base Uptime Kuma push URL (without the monitor-specific endpoint).";
    };

    pools = mkOption {
      type = types.listOf (types.attrsOf types.str);
      example = [
        { pool = "tank"; threshold = "80"; endpoint = "abc123"; }
        { pool = "backup"; threshold = "90"; endpoint = "def456"; }
      ];
      description = ''
        A list of zpools to monitor. Each entry must have:
        - pool: zpool name
        - threshold: percentage threshold
        - endpoint: the Uptime Kuma monitor endpoint (appended to baseUrl)
      '';
    };

    interval = mkOption {
      type = types.str;
      default = "5m";
      example = "10m";
      description = ''
        How often to run the zpool usage monitor.  
        Accepts systemd time spans (e.g. "5m", "30s", "1h").
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.zpool-usage-monitor = {
      description = "ZFS Zpool Usage Monitor for Uptime Kuma";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          script = pkgs.writeShellScript "zpool-usage-monitor.sh" ''
            #!${pkgs.bash}/bin/bash
            set -eu
            pools=(
              ${concatMapStringsSep "\n" (p: ''"${p.pool} ${p.threshold} ${p.endpoint}"'') cfg.pools}
            )

            for entry in "''${pools[@]}"; do
              pool=$(${pkgs.gawk}/bin/awk '{print $1}' <<< "$entry")
              threshold=$(${pkgs.gawk}/bin/awk '{print $2}' <<< "$entry")
              endpoint=$(${pkgs.gawk}/bin/awk '{print $3}' <<< "$entry")
              push_url="${cfg.baseUrl}/$endpoint"

              # Extract capacity usage from zpool list
              percentage=$(${pkgs.zfs}/bin/zpool list -H -o name,capacity | ${pkgs.gawk}/bin/awk -v p="$pool" '$1==p {print $2}')
              number="''${percentage%\%*}"
              message="Used space on zpool $pool is $number% (threshold $threshold%)"

              if [ "$number" -lt "$threshold" ]; then
                service_status="up"
              else
                service_status="down"
              fi

              ${pkgs.curl}/bin/curl \
                --get \
                --data-urlencode "status=$service_status" \
                --data-urlencode "msg=$message" \
                --data-urlencode "ping=$number" \
                --silent \
                "$push_url" \
                > /dev/null
            done
          '';
        in script;
      };
    };

    systemd.timers.zpool-usage-monitor = {
      description = "Run Zpool Usage Monitor every ${cfg.interval}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.interval;
      };
    };
  };
}
