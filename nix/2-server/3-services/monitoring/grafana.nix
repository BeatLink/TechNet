# GRAFANA
#
# Visualization Dashboard for Prometheus

{ pkgs, lib, ... }:
let
    updatesDashboard = {
        title = "NixOS Updates";
        uid = "nixos-updates";
        schemaVersion = 36;
        editable = true;
        panels = [
            {
                title = "Upgrade Service Status";
                type = "stat";
                datasource = {
                    type = "prometheus";
                    uid = "prometheus";
                };
                gridPos = {
                    h = 4;
                    w = 24;
                    x = 0;
                    y = 0;
                };
                targets = [
                    {
                        expr = "node_systemd_unit_state{name=\"nixos-upgrade.service\", state=\"active\"}";
                        legendFormat = "Active State";
                    }
                ];
                fieldConfig.defaults.mappings = [
                    {
                        type = "value";
                        options = {
                            "0" = {
                                text = "Idle";
                                color = "gray";
                            };
                            "1" = {
                                text = "Running";
                                color = "blue";
                            };
                        };
                    }
                ];
            }
            {
                title = "Recent Upgrade Logs";
                type = "logs";
                datasource = {
                    type = "loki";
                    uid = "loki";
                };
                gridPos = {
                    h = 12;
                    w = 24;
                    x = 0;
                    y = 4;
                };
                targets = [
                    {
                        expr = "{unit=\"nixos-upgrade.service\"}";
                    }
                ];
                options = {
                    showLabels = false;
                    showTime = true;
                    sortOrder = "Descending";
                };
            }
        ];
    };
in
{
    services.grafana = {
        enable = true;
        dataDir = "/Storage/Services/Grafana/data";

        provisioning.dashboards.settings.providers = [
            {
                name = "Declarative Dashboards";
                options.path = pkgs.writeTextDir "dashboards/updates.json" (builtins.toJSON updatesDashboard);
            }
        ];

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
