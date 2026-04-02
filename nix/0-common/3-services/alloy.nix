{
    config,
    lib,
    pkgs,
    ...
}:
{
    services.alloy = {
        enable = true;
        extraFlags = [
            "--stability.level=generally-available"
            "--server.http.listen-addr=0.0.0.0:12345"
        ];
    };

    # Alloy uses a separate config file written in Alloy syntax (River).
    # NixOS's alloy module reads from the configPath option, defaulting
    # to a file you manage. We write it via environment.etc.
    environment.etc."alloy/config.alloy" = {
        text = ''
            // ----------------------------------------------------------------
            // Prometheus metrics — scrape local node_exporter and ship to Loki
            // ----------------------------------------------------------------

            prometheus.exporter.unix "node" {
              // Expose standard host metrics (CPU, memory, disk, network)
            }

            prometheus.scrape "node" {
              targets    = prometheus.exporter.unix.node.targets
              forward_to = [prometheus.remote_write.mimir.receiver]

              scrape_interval = "60s"
              scrape_timeout  = "10s"
            }

            // Scrape any local Prometheus-compatible services
            prometheus.scrape "local_services" {
              targets = [
                { "__address__" = "localhost:3100", "job" = "loki"       },
                { "__address__" = "localhost:9093", "job" = "alertmanager" },
              ]
              forward_to      = [prometheus.remote_write.mimir.receiver]
              scrape_interval = "60s"
            }

            // Ship metrics to Prometheus (or Mimir) via remote_write
            prometheus.remote_write "mimir" {
              endpoint {
                url = "http://heimdall.technet:9090/api/v1/write"

                // Uncomment and set if your Prometheus requires auth:
                // basic_auth {
                //   username = "alloy"
                //   password = env("PROMETHEUS_PASSWORD")
                // }
              }

              queue_config {
                capacity             = 10000
                max_samples_per_send = 2000
                batch_send_deadline  = "5s"
              }
            }

            // ----------------------------------------------------------------
            // Log collection — tail systemd journal and ship to Loki
            // ----------------------------------------------------------------

            loki.source.journal "systemd" {
              max_age       = "12h"
              forward_to    = [loki.process.add_labels.receiver]
              relabel_rules = loki.relabel.journal.rules
            }

            // Relabel systemd journal fields into useful Loki labels
            loki.relabel "journal" {
              forward_to = []

              rule {
                source_labels = ["__journal__systemd_unit"]
                target_label  = "unit"
              }
              rule {
                source_labels = ["__journal__hostname"]
                target_label  = "host"
              }
              rule {
                source_labels = ["__journal_priority_keyword"]
                target_label  = "level"
              }
              rule {
                source_labels = ["__journal__transport"]
                target_label  = "transport"
              }
            }

            // Add static labels and drop noisy low-value log lines
            loki.process "add_labels" {
              forward_to = [loki.write.local.receiver]

              stage.static_labels {
                values = {
                  env  = "production",
                  host = env("HOSTNAME"),
                }
              }

              // Drop debug-level logs to reduce volume
              stage.match {
                selector = "{level=\"debug\"}"
                action   = "drop"
              }

              // Parse log lines that look like JSON
              stage.match {
                selector = "{transport=\"stdout\"}"

                stage.json {
                  expressions = {
                    level   = "level",
                    message = "msg",
                  }
                }

                stage.labels {
                  values = {
                    level = "",
                  }
                }
              }
            }

            // Tail additional log files (e.g. nginx, custom apps)
            local.file_match "extra_logs" {
              path_targets = [
                { "__path__" = "/var/log/nginx/*.log", "job" = "nginx" },
                { "__path__" = "/var/log/myapp/*.log", "job" = "myapp" },
              ]
              sync_period = "10s"
            }

            loki.source.file "extra_logs" {
              targets    = local.file_match.extra_logs.targets
              forward_to = [loki.process.add_labels.receiver]
            }

            // Write logs to local Loki instance
            loki.write "local" {
              endpoint {
                url = "http://heimdall.technet:3100/loki/api/v1/push"

                // Uncomment for Loki with auth enabled:
                // basic_auth {
                //   username = "alloy"
                //   password = env("LOKI_PASSWORD")
                // }
              }

              external_labels = {
                collector = "alloy",
              }
            }



            // ----------------------------------------------------------------
            // Alloy self-monitoring — expose its own metrics to Prometheus
            // ----------------------------------------------------------------

            prometheus.scrape "alloy_self" {
              targets    = [{ "__address__" = "localhost:12345" }]
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "alloy"
            }
        '';
        mode = "0644";
    };

    # Point the alloy service at our config file
    systemd.services.alloy = {
        serviceConfig = {
            ExecStart = lib.mkForce (
                "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.alloy"
                + " --stability.level=generally-available"
                + " --server.http.listen-addr=0.0.0.0:12345"
            );

            # Allow alloy to read the journal
            SupplementaryGroups = [ "systemd-journal" ];

            # Secret injection — create /etc/alloy/secrets with:
            #   LOKI_PASSWORD=...
            #   PROMETHEUS_PASSWORD=...
            #   HOSTNAME=myhostname
            EnvironmentFile = lib.mkIf (builtins.pathExists /etc/alloy/secrets) [
                "/etc/alloy/secrets"
            ];
        };
    };

    # Open ports if Alloy receives OTLP from remote services
    # networking.firewall.allowedTCPPorts = [ 4317 4318 12345 ];

    services.prometheus.exporters.node = {
        enable = true;
        port = 9000;
        # For the list of available collectors, run, depending on your install:
        # - Flake-based: nix run
        # - Classic: nix-shell -p prometheus-node-exporter --run "node_exporter --help"
        enabledCollectors = [
            "ethtool"
            "softirqs"
            "systemd"
            "tcpstat"
            "wifi"
            "zfs"
        ];
        # You can pass extra options to the exporter using `extraFlags`, e.g.
        # to configure collectors or disable those enabled by default.
        # Enabling a collector is also possible using "--collector.[name]",
        # but is otherwise equivalent to using `enabledCollectors` above.
        extraFlags = [
            "--collector.ntp.protocol-version=4"
            "--no-collector.mdadm"
        ];
    };

}
