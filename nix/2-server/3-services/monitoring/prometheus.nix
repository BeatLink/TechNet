# Prometheus
#
# Metrics and Monitoring DB
#
# https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters
# https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
#

{ config, ... }:
{
    services.prometheus = {
        enable = true;
        globalConfig.scrape_interval = "10s"; # "1m"
        scrapeConfigs = [
            {
                job_name = "heimdall-node";
                static_configs = [
                    {
                        targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                ];
            }
        ];

    };

}
