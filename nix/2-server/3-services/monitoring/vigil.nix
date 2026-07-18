# Vigil
#
# Web-based network and systems monitor. Runs on Heimdall and pulls metrics,
# service status and backup health from the TechNet hosts over SSH (agentless).
#
# Migrated from Vigil's config.yaml. SSH credentials for the locked-down `vigil`
# service user are supplied once via `ssh_defaults` (username + key) and merged
# into every monitor's `ssh_config` by the engine. Vigil logs into a dedicated
# `vigil-access` account on each host, defined in nix/0-common/2-users/3-vigil.nix.
#
# Repo passphrases are per monitor, not global. Each borg monitor sets
# `passphrase_command` pointing at the sops secret of the tool that owns its
# repo — Vorta's on Odin, borgmatic's on Odin or Heimdall. That command runs on
# the host borg runs on, so Vigil never holds the passphrases and each repo is
# unlocked with its own, exactly as the scheduled job does it. (Vorta and
# borgmatic use different passphrases, so a single Vigil-wide default would
# unlock only one of them.)
#
# Vigil's own SSH key stays in secrets/2-server/vigil.yaml, encrypted to
# Heimdall alone: it is only ever used to log INTO the monitored hosts, which
# Vigil does from here, so no other host needs a copy.
#
# A backup monitor runs `borg create` on the host that owns the source data, and
# borg then opens its own SSH connection to the repo server. That hop
# authenticates with the SOURCE HOST's existing borg key (`ssh_key` on each
# monitor: Vorta's or borgmatic's), never with Vigil's. Vigil therefore triggers
# the host's backup rather than performing one under its own identity, and holds
# no write credential to any backup repository.
#
{ inputs, config, ... }:
{
    imports = [ inputs.vigil.nixosModules.default ];

    # Private SSH key the vigil service user authenticates with, used only to log
    # into the monitored hosts. Owned by the `vigil` service user that runs the
    # daemon here; no other host needs a copy.
    sops.secrets.vigil_ssh_key = {
        sopsFile = "${inputs.self}/secrets/2-server/vigil.yaml";
        owner = "vigil";
    };

    services.vigil = {
        enable = true;
        port = 9611;
        dataDir = "/Storage/Services/Vigil";   # SQLite database lives here (persisted)
        settings = {
            # Applied to every monitor's ssh_config unless overridden locally.
            ssh_defaults = {
                username = "vigil-access";
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
                                    name = "Disk I/O";
                                    id = "ragnarok-diskio";
                                    type = "diskio";
                                    interval = "30s";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Connections";
                                    id = "ragnarok-connections";
                                    type = "connections";
                                    interval = "1m";
                                    total_warning = 500;
                                    total_threshold = 1000;
                                    grid_col_span = 1;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                                {
                                    name = "Interrupts";
                                    id = "ragnarok-interrupts";
                                    type = "interrupts";
                                    interval = "1m";
                                    irq_warning = 20000;
                                    irq_threshold = 50000;
                                    grid_col_span = 1;
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
                                    name = "Disk I/O";
                                    id = "heimdall-diskio";
                                    type = "diskio";
                                    interval = "30s";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Connections";
                                    id = "heimdall-connections";
                                    type = "connections";
                                    interval = "1m";
                                    total_warning = 500;
                                    total_threshold = 1000;
                                    grid_col_span = 1;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Interrupts";
                                    id = "heimdall-interrupts";
                                    type = "interrupts";
                                    interval = "1m";
                                    irq_warning = 20000;
                                    irq_threshold = 50000;
                                    grid_col_span = 1;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Service Reachability";
                                    id = "heimdall-ports";
                                    type = "ports";
                                    interval = "1m";
                                    timeout = 5;
                                    grid_col_span = 4;
                                    checks = [
                                        # nginx fronts every web service on Heimdall; probe the
                                        # local front door plus a few representative app URLs.
                                        { name = "Nginx"; host = "localhost"; port = 443; }
                                        { name = "Home Assistant"; url = "https://home-assistant.heimdall.technet"; }
                                        { name = "Grafana"; url = "https://grafana.heimdall.technet"; }
                                        { name = "Pi-hole"; url = "https://pi-hole.heimdall.technet"; }
                                        { name = "Homepage"; url = "https://homepage.heimdall.technet"; }
                                    ];
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
                                    name = "WiFi";
                                    id = "odin-wifi";
                                    type = "wifi";
                                    interval = "1m";
                                    quality_warning = 40;
                                    quality_threshold = 20;
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    # NVIDIA dGPU (PRIME offload). With finegrained power
                                    # management the card sleeps when idle and nvidia-smi
                                    # can't reach it — the plugin reports `offline` in that
                                    # case rather than `failed`, which is expected here.
                                    name = "GPU";
                                    id = "odin-gpu";
                                    type = "gpu";
                                    interval = "1m";
                                    util_warning = 85;
                                    util_threshold = 95;
                                    mem_warning = 85;
                                    mem_threshold = 95;
                                    temp_warning = 80;
                                    temp_threshold = 90;
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Disk I/O";
                                    id = "odin-diskio";
                                    type = "diskio";
                                    interval = "30s";
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Connections";
                                    id = "odin-connections";
                                    type = "connections";
                                    interval = "1m";
                                    total_warning = 500;
                                    total_threshold = 1000;
                                    grid_col_span = 2;
                                    ssh_config = {
                                        host = "odin.technet";
                                    };
                                }
                                {
                                    name = "Interrupts";
                                    id = "odin-interrupts";
                                    type = "interrupts";
                                    interval = "1m";
                                    irq_warning = 20000;
                                    irq_threshold = 50000;
                                    grid_col_span = 2;
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
                    # Backup monitors, grouped by the host that OWNS THE SOURCE DATA and then by
                    # the tool that manages the repo (Vorta or Borgmatic).
                    #
                    # Grouping follows the host borg RUNS ON, not where the repo lives: `borg
                    # create` archives the filesystem of whichever host executes it, so a monitor
                    # for the laptop's copy on Heimdall must still run on Odin (reaching Heimdall
                    # over ssh://) — otherwise a backup would silently archive Heimdall's
                    # /Storage into the laptop's repo. Each group therefore reads as "what this
                    # host backs up, and where those copies go".
                    #
                    # Every monitor runs `borg` under sudo (`require_sudo`). The repos are
                    # root-owned, so reading an archive as the unprivileged `vigil-access`
                    # account fails on permissions. That account is in `wheel`, and
                    # wheelNeedsPassword = false (nix/0-common/2-users/default.nix) grants it
                    # NOPASSWD:SETENV, so the non-interactive `sudo -n` succeeds and the inlined
                    # BORG_PASSPHRASE survives sudo's env_reset.
                    #
                    # `source_paths`, `exclude` and `compression` mirror the tool that owns each
                    # repo — Vorta's profile settings (Odin's ~/.local/share/Vorta/settings.db)
                    # for the Vorta repos, the borgmatic module for the Borgmatic ones — so a
                    # Vigil-triggered backup produces an archive equivalent to the scheduled one.
                    #
                    # `keep_*` records each repo's retention policy. Vigil has no prune action
                    # yet, so these are inert today; they live here so the policy sits with the
                    # monitor rather than only in the tool that currently prunes.
                    #
                    # Scheduling is deliberately not represented: these backups are triggered
                    # manually from the Vigil UI, while Vorta/borgmatic keep their own schedules.
                    type = "group";
                    children = [
                        {
                            # Odin (the laptop) owns /Storage. Vorta and borgmatic each keep their
                            # own repo set, so both appear here.
                            name = "Odin";
                            type = "group";
                            children = [
                                {
                                    name = "Vorta";
                                    type = "group";
                                    children = [
                                        {
                                            # Odin's local Vorta repo has no "Laptop/" segment — that layout
                                            # is Heimdall's, where the laptop's repo sits alongside the server's.
                                            name = "On Disk";
                                            id = "backup-laptop-on-disk";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "/Storage/Files/Backups/Laptop/Vorta";
                                            require_sudo = true;
                                            # Unlocks this repo with Vorta's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/vorta_backup_passphrase";
                                            source_paths = [
                                                "/Storage"
                                            ];
                                            exclude = [
                                                "**/.cache"
                                                "**/.Trash-1000"
                                                "**/venv"
                                                "**/node_modules"
                                                "**/.flatpak-builder"
                                                "/Storage/System"
                                                "/Storage/Files/Backups"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "odin";
                                            keep_within = "6H";
                                            keep_hourly = 12;
                                            keep_daily = 3;
                                            ssh_config = {
                                                host = "odin.technet";
                                            };
                                        }
                                        {
                                            # Vorta profile "2. Heimdall Backup".
                                            name = "Heimdall";
                                            id = "backup-laptop-heimdall";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Vorta";
                                            require_sudo = true;
                                            # Unlocks this repo with Vorta's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/vorta_backup_passphrase";
                                            # borg makes its OWN SSH connection to the repo server, with
                                            # its own identity — Vigil's login here does not carry over.
                                            # This is Odin's existing Vorta repo key, the same one Vorta
                                            # authenticates with, so Vigil triggers the host's backup
                                            # rather than performing one under its own credentials.
                                            ssh_key = "/run/secrets/vorta_ssh_key";
                                            source_paths = [
                                                "/Storage"
                                            ];
                                            exclude = [
                                                "**/.cache"
                                                "**/.Trash-1000"
                                                "**/venv"
                                                "**/node_modules"
                                                "**/.flatpak-builder"
                                                "/Storage/System"
                                                "/Storage/Files/Backups"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "odin";
                                            keep_within = "6H";
                                            keep_hourly = 12;
                                            keep_daily = 3;
                                            keep_weekly = 2;
                                            keep_monthly = 3;
                                            ssh_config = {
                                                host = "odin.technet";
                                            };
                                        }
                                        {
                                            # Vorta profile "3. Ragnarok Backup" — the long-term copy.
                                            name = "Ragnarok";
                                            id = "backup-laptop-ragnarok";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Vorta";
                                            require_sudo = true;
                                            # Unlocks this repo with Vorta's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/vorta_backup_passphrase";
                                            # borg makes its OWN SSH connection to the repo server, with
                                            # its own identity — Vigil's login here does not carry over.
                                            # This is Odin's existing Vorta repo key, the same one Vorta
                                            # authenticates with, so Vigil triggers the host's backup
                                            # rather than performing one under its own credentials.
                                            ssh_key = "/run/secrets/vorta_ssh_key";
                                            source_paths = [
                                                "/Storage"
                                            ];
                                            exclude = [
                                                "**/.cache"
                                                "**/.Trash-1000"
                                                "**/venv"
                                                "**/node_modules"
                                                "**/.flatpak-builder"
                                                "/Storage/System"
                                                "/Storage/Files/Backups"
                                            ];
                                            exclude_if_present = [
                                                ".nobackup"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "odin";
                                            keep_within = "6H";
                                            keep_hourly = 24;
                                            keep_daily = 30;
                                            keep_weekly = 8;
                                            keep_monthly = 24;
                                            keep_yearly = 3;
                                            ssh_config = {
                                                host = "odin.technet";
                                            };
                                        }
                                    ];
                                }
                                {
                                    name = "Borgmatic";
                                    type = "group";
                                    children = [
                                        {
                                            # This repo does not exist on Odin yet: borgmatic has never completed
                                            # a run there (its borg_repo_ssh_key fails to load — "error in
                                            # libcrypto: unsupported"), so no repo was ever initialised. The path
                                            # matches Odin's borgmatic config; the monitor stays red until that
                                            # key is repaired and borgmatic runs once.
                                            name = "On Disk";
                                            id = "backup-laptop-borgmatic-on-disk";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "/Storage/Files/Backups/Laptop/Borgmatic";
                                            require_sudo = true;
                                            # Unlocks this repo with borgmatic's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/borg_repo_encryption_key";
                                            source_paths = [
                                                "/Storage/System"
                                            ];
                                            exclude_if_present = [
                                                ".nobackup"
                                                ".stversions"
                                                ".thumbnails"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "backup";
                                            keep_hourly = 24;
                                            keep_daily = 7;
                                            keep_weekly = 4;
                                            keep_monthly = 12;
                                            keep_yearly = 3;
                                            ssh_config = {
                                                host = "odin.technet";
                                            };
                                        }
                                        {
                                            name = "Heimdall";
                                            id = "backup-laptop-borgmatic-heimdall";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Borgmatic";
                                            require_sudo = true;
                                            # Unlocks this repo with borgmatic's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/borg_repo_encryption_key";
                                            # borg makes its OWN SSH connection to the repo server, with
                                            # its own identity — Vigil's login here does not carry over.
                                            # This is the host's existing borgmatic key, the same one the
                                            # scheduled job uses, so Vigil triggers the host's backup
                                            # rather than performing one under its own credentials.
                                            ssh_key = "/run/secrets/borg_repo_ssh_key";
                                            source_paths = [
                                                "/Storage/System"
                                            ];
                                            exclude_if_present = [
                                                ".nobackup"
                                                ".stversions"
                                                ".thumbnails"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "backup";
                                            keep_hourly = 24;
                                            keep_daily = 7;
                                            keep_weekly = 4;
                                            keep_monthly = 12;
                                            keep_yearly = 3;
                                            ssh_config = {
                                                host = "odin.technet";
                                            };
                                        }
                                        {
                                            name = "Ragnarok";
                                            id = "backup-laptop-borgmatic-ragnarok";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Borgmatic";
                                            require_sudo = true;
                                            # Unlocks this repo with borgmatic's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/borg_repo_encryption_key";
                                            # borg makes its OWN SSH connection to the repo server, with
                                            # its own identity — Vigil's login here does not carry over.
                                            # This is the host's existing borgmatic key, the same one the
                                            # scheduled job uses, so Vigil triggers the host's backup
                                            # rather than performing one under its own credentials.
                                            ssh_key = "/run/secrets/borg_repo_ssh_key";
                                            source_paths = [
                                                "/Storage/System"
                                            ];
                                            exclude_if_present = [
                                                ".nobackup"
                                                ".stversions"
                                                ".thumbnails"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "backup";
                                            keep_hourly = 24;
                                            keep_daily = 7;
                                            keep_weekly = 4;
                                            keep_monthly = 12;
                                            keep_yearly = 3;
                                            ssh_config = {
                                                host = "odin.technet";
                                            };
                                        }
                                    ];
                                }
                            ];
                        }
                        {
                            # Heimdall (the server) owns /Storage/Services, backed up by borgmatic
                            # only — there is no Vorta on the server.
                            name = "Heimdall";
                            type = "group";
                            children = [
                                {
                                    name = "Borgmatic";
                                    type = "group";
                                    children = [
                                        {
                                            name = "On Disk";
                                            id = "backup-server-on-disk";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "/Storage/Files/Backups/Server/Borgmatic";
                                            require_sudo = true;
                                            # Unlocks this repo with borgmatic's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/borg_repo_encryption_key";
                                            source_paths = [
                                                "/Storage/Services"
                                            ];
                                            exclude = [
                                                "/Storage/Files/Backups/Server"
                                            ];
                                            exclude_if_present = [
                                                ".nobackup"
                                                ".stversions"
                                                ".thumbnails"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "backup";
                                            keep_hourly = 6;
                                            keep_daily = 7;
                                            keep_weekly = 4;
                                            keep_monthly = 3;
                                            keep_yearly = 1;
                                            ssh_config = {
                                                host = "heimdall.technet";
                                            };
                                        }
                                        {
                                            name = "Ragnarok";
                                            id = "backup-server-ragnarok";
                                            type = "borg";
                                            interval = "1h";
                                            max_age = "1d";
                                            repo = "ssh://borg@ragnarok.technet/Storage/Backups/Server/Borgmatic";
                                            require_sudo = true;
                                            # Unlocks this repo with borgmatic's own passphrase, read on the
                                            # host borg runs on. Vorta and borgmatic use different
                                            # passphrases, so this is per monitor rather than global, and
                                            # the secret never leaves the host that owns it.
                                            passphrase_command = "cat /run/secrets/borg_repo_encryption_key";
                                            # borg makes its OWN SSH connection to the repo server, with
                                            # its own identity — Vigil's login here does not carry over.
                                            # This is the host's existing borgmatic key, the same one the
                                            # scheduled job uses, so Vigil triggers the host's backup
                                            # rather than performing one under its own credentials.
                                            ssh_key = "/run/secrets/borg_repo_ssh_key";
                                            source_paths = [
                                                "/Storage/Services"
                                            ];
                                            exclude = [
                                                "/Storage/Files/Backups/Server"
                                            ];
                                            exclude_if_present = [
                                                ".nobackup"
                                                ".stversions"
                                                ".thumbnails"
                                            ];
                                            compression = "lz4";
                                            archive_prefix = "backup";
                                            keep_hourly = 6;
                                            keep_daily = 7;
                                            keep_weekly = 4;
                                            keep_monthly = 3;
                                            keep_yearly = 1;
                                            ssh_config = {
                                                host = "heimdall.technet";
                                            };
                                        }
                                    ];
                                }
                            ];
                        }
                    ];
                }
            ];
        };
    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Vigil 0750 vigil vigil - -"
        "Z /Storage/Services/Vigil 0750 vigil vigil - -"
    ];

    nginx-vhosts.vigil = {
        domain = "vigil.heimdall.technet";
        port = 9611;
    };
}
