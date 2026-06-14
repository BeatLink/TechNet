# GRAFANA
#
# Visualization Dashboard for Prometheus

{ pkgs, lib, ... }:
{
    services.grafana = {
        enable = true;
        dataDir = "/Storage/Services/Grafana/data";

        provision = {
            enable = true;
            dashboards.settings.providers = [
                {
                    name = "Declarative Dashboards";
                    disableDeletion = true;
                    options.path = ./dashboards;
                }
            ];
        };

        settings = {
            security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
            server = {
                http_addr = "127.0.0.1";
                http_port = 3000;
                domain = "grafana.heimdall.technet";
                root_url = "https://grafana.heimdall.technet/";
                serve_from_sub_path = false;
                enforce_domain = false;
                enable_gzip = true;
            };
            analytics.reporting_enabled = false;
        };
    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Grafana 0750 grafana grafana - -"
        "Z /Storage/Services/Grafana 0750 grafana grafana - -"
    ];

    nginx-vhosts.grafana = {
        domain = "grafana.heimdall.technet";
        port = 3000;
    };

}
