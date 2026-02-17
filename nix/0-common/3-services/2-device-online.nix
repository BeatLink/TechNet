{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.device-online;
in
{
  options.services.device-online = {
    enable = mkEnableOption "Enable periodic device-online push service";

    endpoint = mkOption {
      type = types.str;
      default = "HwMYYEvv0G";
      description = "The device-specific endpoint path (only the unique device ID)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.device-online = {
      description = "Push status to Uptime Kuma";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.curl}/bin/curl -fsS --retry 3 'https://uptime-kuma.heimdall.technet/api/push/${cfg.endpoint}?status=up&msg=OK&ping='";
      };
    };

    systemd.timers.device-online = {
      description = "Run device-online every 1 minute";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/1";
        Persistent = true;
      };
    };
  };
}
