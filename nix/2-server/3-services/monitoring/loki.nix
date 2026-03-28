# Loki
#
# Log Aggregator

{
    services.loki = {
        enable = true;
        dataDir = "/Storage/Services/Loki/data";
        configuration = {
            server.http_listen_address = "127.0.0.1";
            auth_enabled = false;
            /*
              schema_config = {
                  configs = [
                      {
                          from = "2023-01-05";
                          index = {
                              period = "24h";
                              prefix = "index_";
                          };
                          object_store = "gcs";
                          schema = "v13";
                          store = "tsdb";
                      }
                  ];
              };
              storage_config = {
                  tsdb_shipper = {
                      active_index_directory = "/Storage/Services/Loki/data/tsdb-index";
                      cache_location = "/Storage/Services/Loki/data/tsdb-cache";
                  };
              };

              query_scheduler = {
                  max_outstanding_requests_per_tenant = 32768;
              };

              querier = {
                  max_concurrent = 16;
              };
            */
        };
        /*
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
        */
    };
    nginx-vhosts.loki = {
        domain = "loki.heimdall.technet";
        port = 3100;
    };

}
