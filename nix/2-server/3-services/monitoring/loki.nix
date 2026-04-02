# Loki
#
# Log Aggregator

{
    services.loki = {
        enable = true;
        dataDir = "/Storage/Services/Loki/data";
        configuration = {
            auth_enabled = false;
            server = {
                http_listen_port = 3100;
                grpc_listen_port = 9096;
                log_level = "info";
            };

            common = {
                instance_addr = "127.0.0.1";
                path_prefix = "/Storage/Services/Loki/data";
                replication_factor = 1;
                ring.kvstore.store = "inmemory";
            };

            schema_config = {
                configs = [
                    {
                        from = "2024-01-01";
                        object_store = "filesystem";
                        store = "tsdb";
                        schema = "v13";
                        index = {
                            prefix = "index_";
                            period = "24h";
                        };
                    }
                ];
            };

            storage_config = {
                tsdb_shipper = {
                    active_index_directory = "/Storage/Services/Loki/data/tsdb-index";
                    cache_location = "/Storage/Services/Loki/data/tsdb-cache";
                    cache_ttl = "24h";
                };
                filesystem = {
                    directory = "/Storage/Services/Loki/data/chunks";
                };
            };

            compactor = {
                working_directory = "/Storage/Services/Loki/data/compactor";
                compaction_interval = "10m";
                retention_enabled = true;
                retention_delete_delay = "2h";
                retention_delete_worker_count = 150;
                delete_request_store = "filesystem";
            };

            limits_config = {
                retention_period = "744h"; # 31 days
                reject_old_samples = true;
                reject_old_samples_max_age = "168h"; # 7 days
                ingestion_rate_mb = 16;
                ingestion_burst_size_mb = 32;
                per_stream_rate_limit = "3MB";
                per_stream_rate_limit_burst = "15MB";
            };

            query_range = {
                results_cache = {
                    cache = {
                        embedded_cache = {
                            enabled = true;
                            max_size_mb = 100;
                        };
                    };
                };
            };

            ruler = {
                storage = {
                    type = "local";
                    local.directory = "/Storage/Services/Loki/data/rules";
                };
                rule_path = "/Storage/Services/Loki/data/rules-temp";
                alertmanager_url = "http://localhost:9093";
                ring.kvstore.store = "inmemory";
                enable_api = true;
            };

            /*
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
