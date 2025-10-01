{ config, ... }:
{
    services.zpool-usage-monitor = {
        enable = true;
        baseUrl = "https://uptime-kuma.heimdall.technet/api/push";
        interval = "10m"; # run every 10 minutes
        pools = [
            {
                pool = "data-pool-${config.networking.hostName}";
                threshold = "90";
                endpoint = "W6JG9cXo4X";
            }
            {
                pool = "root-pool-${config.networking.hostName}";
                threshold = "90";
                endpoint = "OJqTfvQtOh";
            }
        ];
    };
}
