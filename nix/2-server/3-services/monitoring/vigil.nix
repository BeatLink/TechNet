# Vigil
#
# Web-based network and systems monitor. Runs on Heimdall and pulls metrics,
# service status and backup health from the TechNet hosts over SSH (agentless).
#
# Migrated from Vigil's config.yaml. SSH credentials for the locked-down `vigil`
# service user are supplied once via `ssh_defaults` (username + key) and merged
# into every monitor's `ssh_config` by the engine. Vigil logs into a dedicated
# `vigil` account on each host, defined in nix/0-common/2-users/3-vigil.nix.
#
# Prerequisite handled elsewhere:
#   - The borg repo passphrase file (/etc/vigil/borg-laptop.pass) must exist on
#     Heimdall and Ragnarok (read remotely by passphrase_command).
#
{ inputs, config, ... }:
{
    imports = [ inputs.vigil.nixosModules.default ];

    # Private SSH key the vigil service user authenticates with. The default
    # sops path lands under /run/secrets, readable by the vigil user.
    sops.secrets.vigil_ssh_key = {
        sopsFile = "${inputs.self}/secrets/2-server/vigil.yaml";
        owner = "vigil";
    };

    services.vigil = {
        enable = true;
        port = 9611;
        settings = {
            # Applied to every monitor's ssh_config unless overridden locally.
            ssh_defaults = {
                username = "vigil";
                key_path = config.sops.secrets.vigil_ssh_key.path;
            };

            theme = {
                primary = "#00ACFF";
                accent = "#FF5500";
                background = "#FFFFFF";
                background_muted = "#FAFAFA";
                text = "#111827";
                text_muted = "#6B7280";
                status_online = "lime";
                status_warning = "gold";
                status_failed = "red";
                status_offline = "lightgray";
            };

            plugins = [
                {
                    name = "Device Availability";
                    type = "group";
                    children = [
                        {
                            name = "Core Devices";
                            type = "group";
                            children = [
                                {
                                    name = "Ragnarok";
                                    id = "ragnarok";
                                    type = "uptime";
                                    target_host = "ragnarok.technet";
                                    interval = "30s";
                                }
                                {
                                    name = "Heimdall";
                                    id = "heimdall";
                                    type = "uptime";
                                    target_host = "heimdall.technet";
                                    interval = "30s";
                                }
                                {
                                    name = "Odin";
                                    id = "odin";
                                    type = "uptime";
                                    target_host = "odin.technet";
                                    interval = "30s";
                                }
                                {
                                    name = "Thor";
                                    id = "thor";
                                    type = "uptime";
                                    target_host = "thorx.technet";
                                }
                            ];
                        }
                        {
                            name = "IoT Sensors";
                            type = "group";
                            children = [
                                {
                                    name = "Bedroom Light";
                                    id = "bedroom-light";
                                    type = "uptime";
                                    target_host = "light-bedroom.lan";
                                }
                                {
                                    name = "Bedroom Desk Light";
                                    id = "bedroom-desk-light";
                                    type = "uptime";
                                    target_host = "light-bedroom-desk.lan";
                                }
                                {
                                    name = "Kitchen Light";
                                    id = "kitchen-light";
                                    type = "uptime";
                                    target_host = "light-kitchen.lan";
                                }
                                {
                                    name = "Bathroom Light";
                                    id = "bathroom-light";
                                    type = "uptime";
                                    target_host = "light-bathroom.lan";
                                }
                                {
                                    name = "Outside Light";
                                    id = "outside-light";
                                    type = "uptime";
                                    target_host = "light-outside.lan";
                                }
                                {
                                    name = "Fan Socket";
                                    id = "fan-socket";
                                    type = "uptime";
                                    target_host = "socket-fan.lan";
                                }
                                {
                                    name = "Ragnarok Socket";
                                    id = "ragnarok-socket";
                                    type = "uptime";
                                    target_host = "socket-ragnarok.technet";
                                }
                                {
                                    name = "Fan IR";
                                    id = "fan-ir";
                                    type = "uptime";
                                    target_host = "ir-fan.lan";
                                }
                                {
                                    name = "Bedroom Sensor";
                                    id = "bedroom-sensor";
                                    type = "uptime";
                                    target_host = "sensor-bedroom.lan";
                                }
                                {
                                    name = "Bathroom Sensor";
                                    id = "bathroom-sensor";
                                    type = "uptime";
                                    target_host = "sensor-bathroom.lan";
                                }
                            ];
                        }
                    ];
                }
                {
                    name = "System Stats";
                    type = "group";
                    grid_columns = 1;
                    children = [
                        {
                            name = "Ragnarok";
                            type = "group";
                            grid_columns = 4;
                            children = [
                                {
                                    name = "CPU";
                                    id = "ragnarok-cpu";
                                    type = "cpu_usage";
                                    interval = "1m";
                                    cpu_warning = 70;
                                    cpu_threshold = 85;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Memory";
                                    id = "ragnarok-memory";
                                    type = "memory_usage";
                                    interval = "1m";
                                    memory_warning = 75;
                                    memory_threshold = 90;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Temperature";
                                    id = "ragnarok-temperature";
                                    type = "temperature";
                                    interval = "1m";
                                    temp_warning = 70;
                                    temp_threshold = 80;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Load";
                                    id = "ragnarok-load";
                                    type = "load_average";
                                    interval = "1m";
                                    load_warning = 70;
                                    load_threshold = 100;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Processes";
                                    id = "ragnarok-processes";
                                    type = "processes";
                                    interval = "30s";
                                    max_processes = 20;
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Network";
                                    id = "ragnarok-network";
                                    type = "network_usage";
                                    interval = "30s";
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "SMART";
                                    id = "ragnarok-smart";
                                    type = "smart_disk";
                                    interval = "1h";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "ZFS Health";
                                    id = "ragnarok-zfs-health";
                                    type = "zfs_health";
                                    interval = "1h";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "/";
                                    id = "ragnarok-disk-root";
                                    type = "disk_space";
                                    path = "/";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "/Storage";
                                    id = "ragnarok-disk-storage";
                                    type = "disk_space";
                                    path = "/Storage";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "/boot";
                                    id = "ragnarok-disk-boot";
                                    type = "disk_space";
                                    path = "/boot";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                            ];
                        }
                        {
                            name = "Heimdall";
                            type = "group";
                            grid_columns = 4;
                            children = [
                                {
                                    name = "CPU";
                                    id = "heimdall-cpu";
                                    type = "cpu_usage";
                                    interval = "1m";
                                    cpu_warning = 70;
                                    cpu_threshold = 85;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Memory";
                                    id = "heimdall-memory";
                                    type = "memory_usage";
                                    interval = "1m";
                                    memory_warning = 75;
                                    memory_threshold = 90;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Temperature";
                                    id = "heimdall-temperature";
                                    type = "temperature";
                                    interval = "1m";
                                    temp_warning = 70;
                                    temp_threshold = 80;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Load";
                                    id = "heimdall-load";
                                    type = "load_average";
                                    interval = "1m";
                                    load_warning = 70;
                                    load_threshold = 100;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Processes";
                                    id = "heimdall-processes";
                                    type = "processes";
                                    interval = "30s";
                                    max_processes = 20;
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Network";
                                    id = "heimdall-network";
                                    type = "network_usage";
                                    interval = "30s";
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "SMART";
                                    id = "heimdall-smart";
                                    type = "smart_disk";
                                    interval = "1h";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "ZFS Health";
                                    id = "heimdall-zfs-health";
                                    type = "zfs_health";
                                    interval = "1h";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "/";
                                    id = "heimdall-disk-root";
                                    type = "disk_space";
                                    path = "/";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "/Storage";
                                    id = "heimdall-disk-storage";
                                    type = "disk_space";
                                    path = "/Storage";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "/boot";
                                    id = "heimdall-disk-boot";
                                    type = "disk_space";
                                    path = "/boot";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                            ];
                        }
                        {
                            name = "Odin";
                            type = "group";
                            grid_columns = 4;
                            children = [
                                {
                                    name = "CPU";
                                    id = "odin-cpu";
                                    type = "cpu_usage";
                                    interval = "1m";
                                    cpu_warning = 70;
                                    cpu_threshold = 85;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Memory";
                                    id = "odin-memory";
                                    type = "memory_usage";
                                    interval = "1m";
                                    memory_warning = 75;
                                    memory_threshold = 90;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Temperature";
                                    id = "odin-temperature";
                                    type = "temperature";
                                    interval = "1m";
                                    temp_warning = 70;
                                    temp_threshold = 80;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Load";
                                    id = "odin-load";
                                    type = "load_average";
                                    interval = "1m";
                                    load_warning = 70;
                                    load_threshold = 100;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Processes";
                                    id = "odin-processes";
                                    type = "processes";
                                    interval = "30s";
                                    max_processes = 20;
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Network";
                                    id = "odin-network";
                                    type = "network_usage";
                                    interval = "30s";
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "SMART";
                                    id = "odin-smart";
                                    type = "smart_disk";
                                    interval = "1h";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "ZFS Health";
                                    id = "odin-zfs-health";
                                    type = "zfs_health";
                                    interval = "1h";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "/";
                                    id = "odin-disk-root";
                                    type = "disk_space";
                                    path = "/";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "/Storage";
                                    id = "odin-disk-storage";
                                    type = "disk_space";
                                    path = "/Storage";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "/boot";
                                    id = "odin-disk-boot";
                                    type = "disk_space";
                                    path = "/boot";
                                    threshold = 90;
                                    interval = "10m";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                            ];
                        }
                    ];
                }
                {
                    name = "Running Services";
                    type = "group";
                    children = [
                        {
                            name = "Ragnarok";
                            id = "ragnarok-services";
                            type = "group";
                            children = [
                                {
                                    name = "NixOS Upgrade";
                                    id = "ragnarok-nixos-upgrade";
                                    type = "systemd_service";
                                    interval = "1h";
                                    service_name = "nixos-upgrade.service";
                                    max_age = "1w";
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                            ];
                        }
                        {
                            name = "Heimdall";
                            id = "heimdall-services";
                            type = "group";
                            children = [
                                {
                                    name = "NixOS Upgrade";
                                    id = "heimdall-nixos-upgrade";
                                    type = "systemd_service";
                                    interval = "1h";
                                    service_name = "nixos-upgrade.service";
                                    max_age = "1w";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Unbound";
                                    id = "heimdall-unbound";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "unbound.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "VLC";
                                    id = "heimdall-vlc";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "vlc-audio.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Nginx";
                                    id = "heimdall-nginx";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "nginx.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Pi-hole";
                                    id = "heimdall-pihole";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "pihole-ftl.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Home Assistant";
                                    id = "heimdall-home-assistant";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "home-assistant.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Frigate";
                                    id = "heimdall-frigate";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "frigate.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "go2rtc";
                                    id = "heimdall-go2rtc";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "go2rtc.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Loki";
                                    id = "heimdall-loki";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "loki.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Prometheus";
                                    id = "heimdall-prometheus";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "prometheus.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Grafana";
                                    id = "heimdall-grafana";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "grafana.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Uptime Kuma";
                                    id = "heimdall-uptime-kuma";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "uptime-kuma.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "FreshRSS";
                                    id = "heimdall-freshrss";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "phpfpm-freshrss.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "qBittorrent";
                                    id = "heimdall-qbittorrent";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "qbittorrent.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Openbooks";
                                    id = "heimdall-openbooks";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "openbooks.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Traccar";
                                    id = "heimdall-traccar";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "traccar.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "ESPHome";
                                    id = "heimdall-esphome";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "esphome.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Glances";
                                    id = "heimdall-glances";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "glances.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Homepage";
                                    id = "heimdall-homepage";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "homepage-dashboard.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "DDNS Updater";
                                    id = "heimdall-ddns-updater";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "ddns-updater.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Blockurl";
                                    id = "heimdall-blockurl";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "blockurl.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Radicale";
                                    id = "heimdall-radicale";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "radicale.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Syncthing";
                                    id = "heimdall-syncthing";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "syncthing.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Trilium";
                                    id = "heimdall-trilium";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "trilium-server.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                            ];
                        }
                        {
                            name = "Odin";
                            id = "odin-services";
                            type = "group";
                            children = [
                                {
                                    name = "NixOS Upgrade";
                                    id = "odin-nixos-upgrade";
                                    type = "systemd_service";
                                    interval = "1h";
                                    service_name = "nixos-upgrade.service";
                                    max_age = "1w";
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Networking";
                                    id = "odin-networking";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "NetworkManager.service";
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Bluetooth";
                                    id = "local-bluetooth";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "bluetooth.service";
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                            ];
                        }
                    ];
                }
                {
                    name = "Backups";
                    type = "group";
                    children = [
                        {
                            name = "Laptop: On Disk";
                            id = "backup-laptop-on-disk";
                            type = "borg";
                            interval = "1h";
                            max_age = "1d";
                            repo = "/Storage/Files/Backups/Laptop/Vorta";
                            ssh_config = {
                                host = "odin.technet";
                            };
                        }
                        {
                            name = "Laptop: Heimdall";
                            id = "backup-laptop-heimdall";
                            type = "borg";
                            interval = "1h";
                            max_age = "1d";
                            repo = "/Storage/Files/Backups/Laptop/Vorta";
                            passphrase_command = "cat /etc/vigil/borg-laptop.pass";
                            ssh_config = {
                                host = "heimdall.technet";
                            };
                        }
                        {
                            name = "Laptop: Ragnarok";
                            id = "backup-laptop-ragnarok";
                            type = "borg";
                            interval = "1h";
                            max_age = "1d";
                            repo = "/Storage/Backups/Laptop/Vorta";
                            passphrase_command = "cat /etc/vigil/borg-laptop.pass";
                            ssh_config = {
                                host = "ragnarok.technet";
                            };
                        }
                    ];
                }
            ];
        };
    };

    nginx-vhosts.vigil = {
        domain = "vigil.heimdall.technet";
        port = 9611;
    };
}
