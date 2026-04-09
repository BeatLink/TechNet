# GRAFANA
#
# Visualization Dashboard for Prometheus

{
    services.grafana = {
        enable = true;
        dataDir = "/Storage/Services/Grafana/data";
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
    nginx-vhosts.grafana = {
        domain = "grafana.heimdall.technet";
        port = 3000;
    };

}
