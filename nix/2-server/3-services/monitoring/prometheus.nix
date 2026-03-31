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
                        labels.hostname = "Ragnarok";
                        targets = [ "ragnarok.technet:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                    {
                        labels.hostname = "Heimdall";
                        targets = [ "heimdall.technet:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                    {
                        labels.hostname = "Odin";
                        targets = [ "odin.technet:${toString config.services.prometheus.exporters.node.port}" ];
                    }
                ];
            }
            {
                job_name = "pihole";
                static_configs = [
                    {
                        labels.hostname = "Heimdall Pi-Hole";
                        targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.pihole.port}" ];
                    }
                ];
            }
            {
                job_name = "esphome";
                static_configs = [
                    {
                        labels.hostname = "Bedroom Light";
                        targets = [ "light-bedroom.technet" ];
                    }
                    {
                        labels.hostname = "Bedroom Desk Light";
                        targets = [ "light-bedroom-desk.technet" ];
                    }
                    {
                        labels.hostname = "Bathroom Light";
                        targets = [ "light-bathroom.technet" ];
                    }
                    {
                        labels.hostname = "Kitchen Light";
                        targets = [ "light-kitchen.technet" ];
                    }
                    {
                        labels.hostname = "Outside Light";
                        targets = [ "light-outside.technet" ];
                    }
                    {
                        labels.hostname = "Fan IR Blaster";
                        targets = [ "ir-fan.technet" ];
                    }
                    {
                        labels.hostname = "Fan Socket";
                        targets = [ "socket-fan.technet" ];
                    }
                    {
                        labels.hostname = "Ragnarok Socket";
                        targets = [ "socket-ragnarok.technet" ];
                    }
                    {
                        labels.hostname = "Bedroom Motion Sensor";
                        targets = [ "sensor-bedroom.technet" ];
                    }
                    {
                        labels.hostname = "Bathroom Motion Sensor";
                        targets = [ "sensor-bathroom.technet" ];
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
