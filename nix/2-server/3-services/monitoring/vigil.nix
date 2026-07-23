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

    # HTTP Basic Auth credentials gating the dashboard and REST API. The
    # dashboard has no `openFirewall` here, so it's reachable only over the
    # WireGuard mesh — auth is defense-in-depth against anyone else on that
    # mesh, not the internet at large.
    sops.secrets.vigil_dashboard_password = {
        sopsFile = "${inputs.self}/secrets/2-server/vigil.yaml";
        owner = "vigil";
    };

    # FreeDNS's per-host dynamic update URL for bltechnet.mooo.com — a
    # secret, account-specific URL that updates the record to the caller's
    # apparent IP on GET. Read by the "DDNS" monitor's ddns_updater plugin
    # (update_url_file) below. Replaces the standalone ddns-updater service.
    sops.secrets.freedns_update_url = {
        sopsFile = "${inputs.self}/secrets/2-server/vigil.yaml";
        owner = "vigil";
    };

    services.vigil = {
        enable = true;
        port = 9611;
        dataDir = "/Storage/Services/Vigil";   # SQLite database lives here (persisted)
        authUsername = "admin";
        authPasswordFile = config.sops.secrets.vigil_dashboard_password.path;
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
                    # Vigil watching itself. Runs in-process on Heimdall rather
                    # than over SSH, so it needs no ssh_config.
                    #
                    # The value here is the stall check: if the engine wedges,
                    # every other monitor simply stops updating while the UI
                    # keeps serving their last known statuses — a screen full of
                    # green that is indistinguishable from a healthy one. This
                    # monitor is what makes that failure visible.
                    #
                    # Necessarily blind to Vigil being down entirely: a dead
                    # process cannot report its own death. That gap closes with
                    # external alerting, not from here.
                    name = "Vigil";
                    id = "vigil-self";
                    type = "vigil_self";
                    interval = "1m";
                    # Vigil idles around 70 MB with this monitor count; these
                    # leave generous headroom while still catching a real leak.
                    memory_warning = 256;
                    memory_threshold = 512;
                }
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
                    # Keeps bltechnet.mooo.com pointed at the home connection's
                    # current public IP — this is also the WireGuard endpoint for
                    # the laptop, phone, and backup server (see their networking.nix
                    # files), so a stale record breaks remote access to all three.
                    # Replaces the standalone ddns-updater service: Vigil now both
                    # performs the update and reports on whether it's in sync,
                    # instead of a separate opaque container doing the former with
                    # no visibility into the latter.
                    #
                    # Checked against 8.8.8.8 rather than the local Pi-hole/Unbound
                    # resolver: Pi-hole has a hosts-file override for this exact
                    # name pointing at the LAN IP (pi-hole.nix), so asking it would
                    # return that override and never notice a real DDNS failure.
                    # 8.8.8.8 matches the old ddns-updater's own RESOLVER_ADDRESS,
                    # for the same reason.
                    name = "DDNS";
                    id = "ddns-bltechnet";
                    type = "ddns_updater";
                    domain = "bltechnet.mooo.com";
                    record_type = "A";
                    resolver = "8.8.8.8";
                    update_url_file = config.sops.secrets.freedns_update_url.path;
                    interval = "5m";
                }
                {
                    name = "System Stats";
                    type = "group";
                    grid_columns = 2;
                    children = [
                        {
                            name = "Ragnarok";
                            type = "group";
                            grid_columns = 2;
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
                                    # An OOM kill is an event, not a level: memory
                                    # returns to normal before the next sample, so
                                    # memory_usage above cannot see it. Reads the
                                    # cumulative counter, so no kill is ever missed.
                                    name = "OOM Kills";
                                    id = "ragnarok-oom";
                                    type = "oom";
                                    interval = "1m";
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
                                {
                                    # Auto-discovers every mount, so it also covers
                                    # filesystems not listed explicitly above. Catches
                                    # read-only remounts (which leave df reporting
                                    # healthy usage forever) and inode exhaustion.
                                    name = "Filesystems";
                                    id = "ragnarok-filesystems";
                                    type = "filesystems";
                                    interval = "10m";
                                    warning = 80;
                                    threshold = 90;
                                    inode_warning = 85;
                                    inode_threshold = 95;
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "ragnarok.technet";
                                    };
                                }
                            ];
                        }
                        {
                            name = "Heimdall";
                            type = "group";
                            grid_columns = 2;
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
                                    # An OOM kill is an event, not a level: memory
                                    # returns to normal before the next sample, so
                                    # memory_usage above cannot see it. Reads the
                                    # cumulative counter, so no kill is ever missed.
                                    name = "OOM Kills";
                                    id = "heimdall-oom";
                                    type = "oom";
                                    interval = "1m";
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
                                        { name = "Pi-hole"; url = "https://pi-hole.heimdall.technet"; }
                                        { name = "Homepage"; url = "https://homepage.heimdall.technet"; }
                                        { name = "Jackett"; url = "https://jackett.heimdall.technet"; }
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
                                {
                                    # Auto-discovers every mount, so it also covers
                                    # filesystems not listed explicitly above. Catches
                                    # read-only remounts (which leave df reporting
                                    # healthy usage forever) and inode exhaustion.
                                    name = "Filesystems";
                                    id = "heimdall-filesystems";
                                    type = "filesystems";
                                    interval = "10m";
                                    warning = 80;
                                    threshold = 90;
                                    inode_warning = 85;
                                    inode_threshold = 95;
                                    grid_col_span = 4;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                            ];
                        }
                        {
                            name = "Odin";
                            type = "group";
                            grid_columns = 2;
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
                                    # An OOM kill is an event, not a level: memory
                                    # returns to normal before the next sample, so
                                    # memory_usage above cannot see it. Reads the
                                    # cumulative counter, so no kill is ever missed.
                                    name = "OOM Kills";
                                    id = "odin-oom";
                                    type = "oom";
                                    interval = "1m";
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
                                {
                                    # Auto-discovers every mount, so it also covers
                                    # filesystems not listed explicitly above. Catches
                                    # read-only remounts (which leave df reporting
                                    # healthy usage forever) and inode exhaustion.
                                    name = "Filesystems";
                                    id = "odin-filesystems";
                                    type = "filesystems";
                                    interval = "10m";
                                    warning = 80;
                                    threshold = 90;
                                    inode_warning = 85;
                                    inode_threshold = 95;
                                    grid_col_span = 4;
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
                                    # Timer-driven oneshot (OnCalendar=daily). Monitored
                                    # in oneshot mode so a job that silently stops firing
                                    # is caught by max_age — a plain is-active check would
                                    # read "inactive" as healthy between runs.
                                    name = "Stremio Export";
                                    id = "heimdall-stremio-export";
                                    type = "systemd_service";
                                    interval = "1h";
                                    service_name = "stremio-export.service";
                                    max_age = "2d";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    # OnCalendar=daily oneshot, same rationale as above.
                                    name = "Trakt.tv Backup";
                                    id = "heimdall-trakttv-backup";
                                    type = "systemd_service";
                                    interval = "1h";
                                    service_name = "trakttv-backup.service";
                                    max_age = "2d";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    # OnCalendar=monthly. Refreshes the Trakt.tv OAuth
                                    # token; if it stops running the backup above starts
                                    # failing on expired credentials, so it is worth
                                    # catching here rather than via the backup's fallout.
                                    name = "Trakt.tv Auth";
                                    id = "heimdall-trakttv-auth";
                                    type = "systemd_service";
                                    interval = "6h";
                                    service_name = "trakttv-auth.service";
                                    max_age = "5w";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Mosquitto";
                                    id = "heimdall-mosquitto";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "mosquitto.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    # Message-delivery health, as opposed to the
                                    # monitor above, which only proves the broker
                                    # process is running. The failure this exists
                                    # to catch: the broker accepts connections
                                    # while routing itself is wedged (a
                                    # persistence-file jam, a socket wired to a
                                    # dead internal queue) — every liveness check
                                    # stays green while every client silently
                                    # stops seeing messages. Publishes a nonce and
                                    # confirms it comes back on the same topic,
                                    # authenticating as a dedicated `vigil` MQTT
                                    # user (mosquitto.nix) scoped by ACL to
                                    # vigil/probe/# only.
                                    name = "Mosquitto Delivery";
                                    id = "heimdall-mosquitto-delivery";
                                    type = "mosquitto";
                                    interval = "5m";
                                    host = "127.0.0.1";
                                    port = 1883;
                                    username = "vigil";
                                    password_command = "cat /run/secrets/mosquitto_vigil_password";
                                    probe_topic = "vigil/probe/heimdall-mosquitto-delivery";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Calibre Web";
                                    id = "heimdall-calibre-web";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "calibre-web-automated.service";
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    # Library-serving health, as opposed to the
                                    # monitor above, which only proves the
                                    # process is running. Requests /opds with
                                    # a dedicated "vigil" account (created once
                                    # by hand — see calibre-web-automated.nix)
                                    # and checks the body is a real feed, not
                                    # just any 200 — a known upstream issue
                                    # means even a broken metadata DB can
                                    # answer 200 on some routes.
                                    name = "Calibre Web Library";
                                    id = "heimdall-calibre-web-library";
                                    type = "calibre_web";
                                    interval = "10m";
                                    url = "http://127.0.0.1:8083";
                                    username = "vigil";
                                    password_command = "cat /run/secrets/calibre_web_vigil_password";
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
                                    # Resolution health, as opposed to the monitor
                                    # above, which only proves the daemon is
                                    # running. The failure this exists to catch:
                                    # the process stays up and the socket stays
                                    # open while recursion itself is broken (stale
                                    # root hints, no outbound path, a validation
                                    # wedge) — every liveness check reports that
                                    # as healthy. Reads unbound-control's stats
                                    # socket (see unbound.nix's
                                    # localControlSocketPath) and issues one live
                                    # query, both over SSH on Heimdall itself, so
                                    # no new network exposure is added.
                                    name = "Unbound Resolution";
                                    id = "heimdall-unbound-resolution";
                                    type = "unbound";
                                    interval = "5m";
                                    query_host = "127.0.0.1";
                                    query_port = 5335;
                                    query_domain = "cloudflare.com";
                                    servfail_warning = 5;
                                    servfail_threshold = 20;
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
                                    # DNS filtering health, as opposed to the
                                    # monitor above, which only proves FTL is
                                    # running. The failure this exists to catch:
                                    # gravity stops matching, so Pi-hole resolves
                                    # normally while blocking nothing — invisible
                                    # to every liveness check.
                                    #
                                    # Port 9018 is the pihole-web listener on
                                    # Heimdall's loopback (see pi-hole.nix), so
                                    # the API is read from that host over SSH.
                                    # It answers locally without a session token,
                                    # hence no api_password here.
                                    name = "Pi-hole DNS";
                                    id = "heimdall-pihole-dns";
                                    type = "pihole";
                                    interval = "5m";
                                    api_url = "http://127.0.0.1:9018";
                                    # Steady state sits near 16%. A drop under 5%
                                    # means filtering has degraded; under 1% it has
                                    # effectively stopped.
                                    block_rate_warning = 5;
                                    block_rate_threshold = 1;
                                    # Gravity rebuilds weekly by default, so 8d
                                    # flags a rebuild that silently stopped
                                    # happening without alarming on the normal cycle.
                                    gravity_max_age = "8d";
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
                                    # Camera health, as opposed to the monitor
                                    # above, which only proves the process is
                                    # running. Reads Frigate's own precomputed
                                    # connection_quality per camera via its
                                    # internal (unauthenticated-by-design,
                                    # loopback-only) API on port 5000 — no
                                    # credential needed, no change to the real
                                    # auth setup on the regular port.
                                    name = "Frigate Cameras";
                                    id = "heimdall-frigate-cameras";
                                    type = "frigate";
                                    interval = "1m";
                                    api_url = "http://127.0.0.1:5000";
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
                                    # Feed-refresh health, as opposed to the
                                    # monitor above, which only proves
                                    # PHP-FPM is running. Reads per-feed
                                    # last-updated timestamps via the Fever
                                    # API — the account's separate API
                                    # password is set once by hand (see
                                    # freshrss.nix) since FreshRSS has no
                                    # declarative option for it.
                                    name = "FreshRSS Feeds";
                                    id = "heimdall-freshrss-feeds";
                                    type = "freshrss";
                                    interval = "15m";
                                    api_url = "http://127.0.0.1:80";
                                    username = "beatlink";
                                    api_password_command = "cat /run/secrets/freshrss_api_password";
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
                                    # Transfer health, as opposed to the monitor
                                    # above, which only proves the daemon is
                                    # running. The failure this exists to catch:
                                    # the daemon keeps running while transfers
                                    # have silently stopped — no peer
                                    # connectivity, or the storage path went
                                    # away — which every liveness check reports
                                    # as healthy.
                                    #
                                    # Port 9050 is the WebUI listener on
                                    # Heimdall (see qbittorrent.nix), read from
                                    # that host over SSH so the monitor does not
                                    # depend on the nginx vhost in front of it.
                                    # That config sets LocalHostAuth = false, so
                                    # requests from Heimdall itself need no
                                    # credential and none is stored here. If that
                                    # ever changes, set username together with
                                    # password_command (pointing at a sops
                                    # secret, as the borg monitors do) — the
                                    # plugin reports a rejected login explicitly
                                    # rather than failing obscurely.
                                    #
                                    # Exposes Resume All / Recheck Errored /
                                    # Pause All on the monitor's page. Nothing
                                    # destructive is offered: the dashboard fires
                                    # actions with no confirmation step.
                                    name = "qBittorrent Transfers";
                                    id = "heimdall-qbittorrent-transfers";
                                    type = "qbittorrent";
                                    interval = "5m";
                                    api_url = "http://127.0.0.1:9050";
                                    # A couple of stalled torrents is a dead
                                    # swarm and normal; the whole queue stalling
                                    # at once is the connection, not the peers.
                                    stalled_warning = 3;
                                    stalled_threshold = 10;
                                    # An errored torrent usually means the
                                    # storage path under /Storage disappeared,
                                    # which is worth failing on immediately.
                                    error_threshold = 1;
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
                                    # IRC-bridge health, as opposed to the
                                    # monitor above, which only proves the web
                                    # server is running. Opens one short-lived
                                    # WebSocket connection to confirm the IRC
                                    # bridge to irc.irchighway.net is actually
                                    # connected — closes immediately since
                                    # OpenBooks serves only one client at a
                                    # time. 10m interval keeps this probe's
                                    # share of that single slot small.
                                    name = "Openbooks IRC Bridge";
                                    id = "heimdall-openbooks-irc";
                                    type = "openbooks";
                                    interval = "10m";
                                    ws_url = "ws://127.0.0.1:9777/ws";
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
                                    # Device-staleness health, as opposed to
                                    # the monitor above, which only proves the
                                    # server is running. Authenticates as a
                                    # dedicated read-only "vigil" user created
                                    # once by hand (see traccar.nix, which has
                                    # no declarative user provisioning at all)
                                    # and computes staleness itself from each
                                    # device's lastUpdate, rather than
                                    # trusting Traccar's own status field —
                                    # that field doesn't reliably reach
                                    # "offline" on its own for a tracker that
                                    # has simply gone silent.
                                    name = "Traccar Devices";
                                    id = "heimdall-traccar-devices";
                                    type = "traccar";
                                    interval = "15m";
                                    api_url = "http://127.0.0.1:8082";
                                    username = "vigil";
                                    password_command = "cat /run/secrets/traccar_vigil_password";
                                    stale_warning = 24;
                                    stale_threshold = 72;
                                    ssh_config = {
                                        host = "heimdall.technet";
                                    };
                                }
                                {
                                    name = "Jackett";
                                    id = "heimdall-jackett";
                                    type = "systemd_service";
                                    interval = "1m";
                                    service_name = "jackett.service";
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
                                    # Database health, as opposed to the
                                    # monitor above, which only proves the
                                    # process is running. Reads the domain
                                    # list via BlockURL's own X-API-Key auth
                                    # (blockurl.nix's existing secret — no new
                                    # credential needed) and checks it is
                                    # non-empty, catching a corrupted or
                                    # wiped database that a liveness check
                                    # cannot see.
                                    name = "Blockurl Database";
                                    id = "heimdall-blockurl-database";
                                    type = "blockurl";
                                    interval = "15m";
                                    api_url = "http://127.0.0.1:9001";
                                    api_key_command = "cut -d= -f2- /run/secrets/blockurl_api_key";
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
                                    # CalDAV/CardDAV health, as opposed to the
                                    # monitor above, which only proves the
                                    # process is running. Radicale has no JSON
                                    # API at all — issues a live PROPFIND as a
                                    # dedicated "vigil" htpasswd account
                                    # (provisioned declaratively; see
                                    # radicale.nix) and checks for the 207
                                    # Multi-Status a healthy WebDAV server
                                    # returns.
                                    name = "Radicale WebDAV";
                                    id = "heimdall-radicale-webdav";
                                    type = "radicale";
                                    interval = "10m";
                                    url = "http://127.0.0.1:5232";
                                    username = "vigil";
                                    password_command = "cat /run/secrets/radicale_vigil_password";
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
                                    # Folder/device health, as opposed to the
                                    # monitor above, which only proves the
                                    # daemon is running. Reads Syncthing's own
                                    # REST API, keyed by an API key extracted
                                    # from config.xml by a small Nix-managed
                                    # timer (see syncthing.nix) rather than a
                                    # separately stored credential.
                                    name = "Syncthing Sync Health";
                                    id = "heimdall-syncthing-health";
                                    type = "syncthing";
                                    interval = "10m";
                                    api_url = "http://127.0.0.1:8384";
                                    api_key_command = "cat /Storage/Services/Syncthing/Config/vigil-api-key";
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
                                {
                                    # Write-activity health, as opposed to the
                                    # monitor above, which only proves the
                                    # process is running. Reads
                                    # statistics.lastModified via ETAPI, using
                                    # a token generated once by hand (see
                                    # trilium.nix, which has no declarative
                                    # token provisioning at all). Staleness
                                    # here can be entirely normal (nobody used
                                    # Trilium overnight), so the default
                                    # window is generous and meant to be
                                    # tuned per instance.
                                    name = "Trilium Activity";
                                    id = "heimdall-trilium-activity";
                                    type = "trilium";
                                    interval = "1h";
                                    api_url = "http://127.0.0.1:8080";
                                    token_command = "cat /run/secrets/trilium_etapi_token";
                                    stale_warning = 72;
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
                            # Explicit id: without one it defaults to the name and collides with the "Odin" group under System Stats,
                            # so both would write status under the same key.
                            id = "backups-odin";
                            type = "group";
                            children = [
                                {
                                    name = "Vorta";
                                    id = "backups-odin-vorta";
                                    type = "group";
                                    children = [
                                        {
                                            # Odin's local Vorta repo has no "Laptop/" segment — that layout
                                            # is Heimdall's, where the laptop's repo sits alongside the server's.
                                            name = "On Disk";
                                            id = "backup-laptop-on-disk";
                                            type = "borg";
                                            interval = "15m";
                                            # Local repo — no second SSH hop, so this answers far faster than
                                            # the pushed copies.
                                            timeout = "5m";
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
                                            # Remote repo on the backup server, whose data pool is a single
                                            # USB disk (~13 MB/s): a read can take many minutes when the pool
                                            # is busy. Long timeout so a slow answer still counts, wide
                                            # interval so polls cannot stack up behind each other. The timeout stays
                                            # well under the interval, so a poll that runs to its
                                            # deadline is killed before the next one is due.
                                            timeout = "30m";
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
                                            # Remote repo on the backup server, whose data pool is a single
                                            # USB disk (~13 MB/s): a read can take many minutes when the pool
                                            # is busy. Long timeout so a slow answer still counts, wide
                                            # interval so polls cannot stack up behind each other. The timeout stays
                                            # well under the interval, so a poll that runs to its
                                            # deadline is killed before the next one is due.
                                            timeout = "30m";
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
                                    # Explicit id: without one it defaults to the name and both host groups have a "Borgmatic" child,
                                    # so both would write status under the same key.
                                    id = "backups-odin-borgmatic";
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
                                            interval = "15m";
                                            # Local repo — no second SSH hop, so this answers far faster than
                                            # the pushed copies.
                                            timeout = "5m";
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
                                            # Remote repo on the backup server, whose data pool is a single
                                            # USB disk (~13 MB/s): a read can take many minutes when the pool
                                            # is busy. Long timeout so a slow answer still counts, wide
                                            # interval so polls cannot stack up behind each other. The timeout stays
                                            # well under the interval, so a poll that runs to its
                                            # deadline is killed before the next one is due.
                                            timeout = "30m";
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
                                            # Remote repo on the backup server, whose data pool is a single
                                            # USB disk (~13 MB/s): a read can take many minutes when the pool
                                            # is busy. Long timeout so a slow answer still counts, wide
                                            # interval so polls cannot stack up behind each other. The timeout stays
                                            # well under the interval, so a poll that runs to its
                                            # deadline is killed before the next one is due.
                                            timeout = "30m";
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
                            # Explicit id: without one it defaults to the name and collides with the "Heimdall" group under System Stats,
                            # so both would write status under the same key.
                            id = "backups-heimdall";
                            type = "group";
                            children = [
                                {
                                    name = "Borgmatic";
                                    id = "backups-heimdall-borgmatic";
                                    type = "group";
                                    children = [
                                        {
                                            name = "On Disk";
                                            id = "backup-server-on-disk";
                                            type = "borg";
                                            interval = "15m";
                                            # Local repo — no second SSH hop, so this answers far faster than
                                            # the pushed copies.
                                            timeout = "5m";
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
                                            # Remote repo on the backup server, whose data pool is a single
                                            # USB disk (~13 MB/s): a read can take many minutes when the pool
                                            # is busy. Long timeout so a slow answer still counts, wide
                                            # interval so polls cannot stack up behind each other. The timeout stays
                                            # well under the interval, so a poll that runs to its
                                            # deadline is killed before the next one is due.
                                            timeout = "30m";
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
