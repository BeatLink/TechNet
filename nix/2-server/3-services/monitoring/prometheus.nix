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
        extraFlags = [
            "--web.enable-remote-write-receiver"
        ];
        # Remote-write receiver. Grafana Alloy was the sole producer until it
        # was removed from the TechNet in favour of Vigil; nothing writes here
        # now, so this only matters if a push-based collector is reintroduced.
        configText = ''
            remote_write:
              - url: "http://prometheus.heimdall.technet/api/v1/write"
                send_exemplars: true
        '';
        scrapeConfigs = [
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
                        targets = [ "light-bedroom.lan" ];
                    }
                    {
                        labels.hostname = "Bedroom Desk Light";
                        targets = [ "light-bedroom-desk.lan" ];
                    }
                    {
                        labels.hostname = "Bathroom Light";
                        targets = [ "light-bathroom.lan" ];
                    }
                    {
                        labels.hostname = "Kitchen Light";
                        targets = [ "light-kitchen.lan" ];
                    }
                    {
                        labels.hostname = "Outside Light";
                        targets = [ "light-outside.lan" ];
                    }
                    {
                        labels.hostname = "Fan IR Blaster";
                        targets = [ "ir-fan.lan" ];
                    }
                    {
                        labels.hostname = "Fan Socket";
                        targets = [ "socket-fan.lan" ];
                    }
                    {
                        labels.hostname = "Bedroom Motion Sensor";
                        targets = [ "sensor-bedroom.lan" ];
                    }
                    {
                        labels.hostname = "Bathroom Motion Sensor";
                        targets = [ "sensor-bathroom.lan" ];
                    }
                    {
                        labels.hostname = "Ragnarok Socket";
                        targets = [ "socket-ragnarok.technet" ];
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
