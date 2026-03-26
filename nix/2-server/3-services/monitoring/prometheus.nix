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
        globalConfig = {
            scrape_interval = "60s"; # "1m"
            scrape_timeout = "30s";
        };
        scrapeConfigs = [
            {
                job_name = "node";
                static_configs = [
                    {
                        labels.host = "Ragnarok";
                        targets = [ "ragnarok.technet:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                    {
                        labels.host = "Heimdall";
                        targets = [ "heimdall.technet:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                    {
                        labels.host = "Odin";
                        targets = [ "odin.technet:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                ];
            }
            {
                job_name = "pihole";
                static_configs = [
                    {
                        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.pihole.port}" ];
                    }
                ];
            }
        ];

    };
    environment.persistence."/Storage/Services/Prometheus".directories = [ "/var/lib/prometheus2" ];

    nginx-vhosts.prometheus = {
        domain = "prometheus.heimdall.technet";
        port = 9090;
    };

}
