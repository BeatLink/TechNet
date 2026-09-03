# Vigil
#
# Web-based network and systems monitor. Runs on Heimdall and collects metrics,
# service status and backup health from the TechNet hosts.
#
# Heimdall, Odin and Ragnarok are reached through the Vigil agent: each runs
# `vigil-agent` (nix/0-common/3-services/vigil-agent.nix), which dials out to
# this host and holds one WebSocket open. Monitors name their host with
# `agent = "<id>"`. Nothing about a monitor's commands changes — the agent runs
# the same shell the SSH transport carried — but there is no per-host session
# ceiling, no SSH channel per command, and monitors that subscribe to an event
# stream hear about a change immediately instead of on their next interval.
#
# `ssh_defaults` below is retained as a fallback, not as the collection path.
# No monitor sets `ssh_config` any more, so nothing uses it; it stays until the
# agents have proven themselves, because restoring SSH access to a host you can
# no longer see is the wrong order of operations. Drop it, and the
# `vigil-access` account, once that is settled.
#
# Devices with nothing to run — the IoT sensors, lights and Thor — are still
# reached agentlessly by ICMP/HTTP/DNS, which needs nothing installed on them.
# That is the case the agent does not replace and is why SSH and the other
# agentless transports remain first-class.
#
# Repo passphrases are per monitor, not global. Each borg monitor sets
# `passphrase_command` pointing at the sops secret of the tool that owns its
# repo — Vorta's on Odin, borgmatic's on Odin or Heimdall. That command runs on
# the host borg runs on, so Vigil never holds the passphrases and each repo is
# unlocked with its own, exactly as the scheduled job does it. (Vorta and
# borgmatic use different passphrases, so a single Vigil-wide default would
# unlock only one of them.)
#
# Every signal a host reports is its own monitor and its own plugin type: `cpu`,
# `memory`, `smart`, `throughput` and the rest each collect one thing. Each
# therefore carries its own status, interval and history — smart reads hourly
# while cpu reads every minute, and a failing pool shows as a failing ZFS
# monitor rather than as one degraded "Disks" roll-up.
#
# The tree is one group per host, then per domain. Each host holds
# `Availability`, `System Stats` (Compute, Memory, Storage, Network),
# `Running Services`, and `Backups` where it owns source data. A group reports
# the worst case of its children, so a host still collapses to one status.
#
# Under `Running Services` each service is its own group holding its unit check
# and whatever functional check proves it is actually serving — Mosquitto's
# delivery probe, Radicale's WebDAV request, Pi-hole's resolution — so a unit
# that is up but not working reads as a failure rather than averaging away.
#
# The lights, sockets and sensors are not TechNet hosts and have no domains, so
# they stay in one top-level `IoT Sensors` group of reachability checks.
#
# Group names now repeat across hosts, so every group carries an explicit `id`:
# an id defaults to the name, and three hosts sharing a "System Stats" would
# otherwise write their status under one key.
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
# Backups are grouped under the host borg RUNS ON, not where the repo lives:
# `borg create` archives the filesystem of whichever host executes it, so the
# monitor for the laptop's copy on Heimdall still belongs to Odin (reaching
# Heimdall over ssh://) — otherwise a backup would silently archive Heimdall's
# /Storage into the laptop's repo. Each group reads as "what this host backs up,
# and where those copies go".
#
# Every backup monitor runs `borg` under sudo (`require_sudo`). The repos are
# root-owned, so reading an archive as the unprivileged `vigil-access` account
# fails on permissions. That account is in `wheel`, and wheelNeedsPassword =
# false (nix/0-common/2-users/default.nix) grants it NOPASSWD:SETENV, so the
# non-interactive `sudo -n` succeeds and the inlined BORG_PASSPHRASE survives
# sudo's env_reset.
#
# `source_paths`, `exclude` and `compression` mirror the tool that owns each
# repo — Vorta's profile settings (Odin's ~/.local/share/Vorta/settings.db) for
# the Vorta repos, the borgmatic module for the Borgmatic ones — so a
# Vigil-triggered backup produces an archive equivalent to the scheduled one.
#
# `keep_*` records each repo's retention policy. Vigil has no prune action yet,
# so these are inert today; they live here so the policy sits with the monitor
# rather than only in the tool that currently prunes.
#
# Scheduling is deliberately not represented: these backups are triggered
# manually from the Vigil UI, while Vorta/borgmatic keep their own schedules.
#
{ config, inputs, ... }:
let
    # Every host upgrades from the same flake, so Heimdall's own value is every monitor's.
    upgradeFlake = config.system.autoUpgrade.flake;
in
{
    imports = [ inputs.vigil.nixosModules.default ];

    # Private SSH key the vigil service user authenticates with, used only to log
    # into the monitored hosts. Owned by the `vigil` service user that runs the
    # daemon here; no other host needs a copy.
    sops.secrets.vigil_ssh_key = {
        sopsFile = "${config.technet.secrets.path}/vigil.yaml";
        owner = "vigil";
    };

    # Login credentials gating the dashboard and REST API. The
    # dashboard has no `openFirewall` here, so it's reachable only over the
    # WireGuard mesh — auth is defense-in-depth against anyone else on that
    # mesh, not the internet at large.
    sops.secrets.vigil_dashboard_password = {
        sopsFile = "${config.technet.secrets.path}/vigil.yaml";
        owner = "vigil";
    };

    # Signs the dashboard session cookies, so a Vigil restart or redeploy does not sign every browser out.
    sops.secrets.vigil_session_secret = {
        sopsFile = "${config.technet.secrets.path}/vigil.yaml";
        owner = "vigil";
    };

    # Shared token each agent authenticates with, one file per agent. Heimdall
    # is a recipient of all three (it declares every agent below); each host is
    # a recipient only of its own, so no monitored host can impersonate
    # another's agent. Read at runtime via `token_file`, so the tokens never
    # enter the Nix store the way an inline `token` in `settings` would.
    sops.secrets.vigil_agent_token_heimdall = {
        sopsFile = "${config.technet.secrets.commonPath}/vigil-agent-heimdall.yaml";
        key = "vigil_agent_token";
        owner = "vigil";
    };

    sops.secrets.vigil_agent_token_odin = {
        sopsFile = "${config.technet.secrets.commonPath}/vigil-agent-odin.yaml";
        key = "vigil_agent_token";
        owner = "vigil";
    };

    sops.secrets.vigil_agent_token_ragnarok = {
        sopsFile = "${config.technet.secrets.commonPath}/vigil-agent-ragnarok.yaml";
        key = "vigil_agent_token";
        owner = "vigil";
    };

    # FreeDNS's per-host dynamic update URL for bltechnet.mooo.com — a
    # secret, account-specific URL that updates the record to the caller's
    # apparent IP on GET. Read by the "DDNS" monitor's ddns_updater plugin
    # (update_url_file) below. Replaces the standalone ddns-updater service.
    sops.secrets.freedns_update_url = {
        sopsFile = "${config.technet.secrets.path}/vigil.yaml";
        owner = "vigil";
    };

    # HTTP plugins run `api_password_command` here as the `vigil` user, not through the agent, so it needs the same credential group the agent holds.
    users.users.vigil.extraGroups = [ "vigil-monitor" ];

    services.vigil = {
        enable = true;
        port = 9611;
        dataDir = "/Storage/Services/Vigil";   # SQLite database lives here (persisted)
        authUsername = "admin";
        authPasswordFile = config.sops.secrets.vigil_dashboard_password.path;
        authSessionSecretFile = config.sops.secrets.vigil_session_secret.path;
        settings = {
            # Batches queued metric/status/event/log writes into one commit
            # every N seconds instead of committing each individually, cutting
            # disk fsyncs under load at the cost of losing up to N seconds of
            # unwritten data on a crash — acceptable for monitoring data.
            # Matches the engine default; set explicitly so it's visible here.
            database = {
                write_batch_seconds = 5;
            };

            # Every agent that may dial in. A monitor's `agent = "<id>"` refers
            # to an `id` here. `host` is a label only — Vigil never dials an
            # agent, the agent always dials Vigil — but it is what a monitor's
            # target shows as in the dashboard, so it stays the real hostname.
            #
            # An agent that is configured but not currently connected is not an
            # error: its monitors report failed with an explicit message until
            # it reconnects, exactly as a refused SSH dial behaved.
            agents = [
                {
                    id = "heimdall";
                    host = "heimdall.technet";
                    token_file = config.sops.secrets.vigil_agent_token_heimdall.path;
                }
                {
                    id = "odin";
                    host = "odin.technet";
                    token_file = config.sops.secrets.vigil_agent_token_odin.path;
                }
                {
                    id = "ragnarok";
                    host = "ragnarok.technet";
                    token_file = config.sops.secrets.vigil_agent_token_ragnarok.path;
                }
            ];

            # Fallback only — no monitor sets `ssh_config` any more, so nothing
            # merges these today. See the header before removing them.
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
                    name = "Ragnarok";
                    id = "ragnarok-host";
                    type = "group";
                    children = [
                        {
                            name = "Availability";
                            id = "ragnarok";
                            type = "uptime";
                            target_host = "ragnarok.technet";
                            interval = "30s";
                        }
                        {
                            name = "System Stats";
                            # Explicit id: a group id defaults to its name and every host has this group, so all three would share one key.
                            id = "ragnarok-metrics";
                            type = "group";
                            children = [
                                {
                                    name = "Compute";
                                    id = "ragnarok-compute";
                                    type = "group";
                                    children = [
                                        {
                                            name = "CPU";
                                            id = "ragnarok-cpu";
                                            type = "cpu";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 85;
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "Load";
                                            id = "ragnarok-load";
                                            type = "load";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 100;
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "Temperature";
                                            id = "ragnarok-temperature";
                                            type = "temperature";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 80;
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "Interrupts";
                                            id = "ragnarok-interrupts";
                                            type = "interrupts";
                                            interval = "1m";
                                            warning = 20000;
                                            threshold = 50000;
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "Processes";
                                            id = "ragnarok-processes";
                                            type = "processes";
                                            interval = "30s";
                                            max_processes = 20;
                                            grid_col_span = 2;
                                            agent = "ragnarok";
                                        }
                                    ];
                                }
                                {
                                    name = "Memory";
                                    id = "ragnarok-memory";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Usage";
                                            id = "ragnarok-memory-usage";
                                            type = "memory";
                                            interval = "1m";
                                            warning = 90;
                                            threshold = 95;
                                            agent = "ragnarok";
                                        }
                                        {
                                            # An OOM kill is an event, not a level: memory is back to normal
                                            # before the next sample, so the usage monitor beside this one cannot
                                            # see it. The counter read each cycle means no kill is ever missed,
                                            # and over this host's agent the module also follows the kernel
                                            # journal, so a kill is reported the moment it happens and names the
                                            # process the counter can only total.
                                            name = "OOM Kills";
                                            id = "ragnarok-oom";
                                            type = "oom";
                                            interval = "1m";
                                            agent = "ragnarok";
                                        }
                                    ];
                                }
                                {
                                    name = "Storage";
                                    id = "ragnarok-storage";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Disk I/O";
                                            id = "ragnarok-disk-io";
                                            type = "disk_io";
                                            interval = "30s";
                                            agent = "ragnarok";
                                        }
                                        {
                                            # smartctl is slow and rarely changes its answer, so this reads hourly.
                                            name = "SMART";
                                            id = "ragnarok-smart";
                                            type = "smart";
                                            interval = "1h";
                                            agent = "ragnarok";
                                        }
                                        {
                                            # A pool changes state slowly and `zpool status` walks every vdev.
                                            name = "ZFS";
                                            id = "ragnarok-zfs";
                                            type = "zfs";
                                            interval = "1h";
                                            warning = 90;
                                            threshold = 96;
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "/";
                                            id = "ragnarok-disk-root";
                                            type = "disk_space";
                                            path = "/";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "/Storage";
                                            id = "ragnarok-disk-storage";
                                            type = "disk_space";
                                            path = "/Storage";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "/boot";
                                            id = "ragnarok-disk-boot";
                                            type = "disk_space";
                                            path = "/boot";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "ragnarok";
                                        }
                                        {
                                            # Auto-discovers every mount, so it also covers filesystems not listed
                                            # explicitly above. Catches read-only remounts (which leave df reporting
                                            # healthy usage forever) and inode exhaustion.
                                            name = "Filesystems";
                                            id = "ragnarok-filesystems";
                                            type = "filesystems";
                                            interval = "10m";
                                            warning = 90;
                                            threshold = 96;
                                            inode_warning = 85;
                                            inode_threshold = 95;
                                            grid_col_span = 2;
                                            agent = "ragnarok";
                                        }
                                    ];
                                }
                                {
                                    name = "Network";
                                    id = "ragnarok-network";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Throughput";
                                            id = "ragnarok-throughput";
                                            type = "throughput";
                                            interval = "30s";
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "Connections";
                                            id = "ragnarok-connections";
                                            type = "connections";
                                            interval = "1m";
                                            warning = 500;
                                            threshold = 1000;
                                            agent = "ragnarok";
                                        }
                                    ];
                                }
                            ];
                        }
                        {
                            name = "Running Services";
                            # Explicit id: a group id defaults to its name and every host has this group, so all three would share one key.
                            id = "ragnarok-services";
                            type = "group";
                            children = [
                                {
                                    name = "NixOS Upgrade";
                                    id = "ragnarok-svc-nixos-upgrade";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "ragnarok-nixos-upgrade";
                                            type = "systemd_service";
                                            interval = "1h";
                                            service_name = "nixos-upgrade.service";
                                            max_age = "1w";
                                            agent = "ragnarok";
                                        }
                                        {
                                            name = "Deployment";
                                            id = "ragnarok-nixos-deployment";
                                            type = "nixos_upgrade";
                                            interval = "5m";
                                            flake = upgradeFlake;
                                            configuration = "Ragnarok";
                                            eval_agent = "heimdall";                  # Evaluating the flake on the 2GB Rock64 swaps it to death within seconds
                                            eval_interval = "6h";
                                            rebuild_args = [ "--no-write-lock-file" "-L" ];
                                            agent = "ragnarok";
                                        }
                                    ];
                                }
                            ];
                        }
                    ];
                }
                {
                    name = "Heimdall";
                    id = "heimdall-host";
                    type = "group";
                    children = [
                        {
                            name = "Availability";
                            id = "heimdall";
                            type = "uptime";
                            target_host = "heimdall.technet";
                            interval = "30s";
                        }
                        {
                            name = "System Stats";
                            # Explicit id: a group id defaults to its name and every host has this group, so all three would share one key.
                            id = "heimdall-metrics";
                            type = "group";
                            children = [
                                {
                                    name = "Compute";
                                    id = "heimdall-compute";
                                    type = "group";
                                    children = [
                                        {
                                            name = "CPU";
                                            id = "heimdall-cpu";
                                            type = "cpu";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 85;
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "Load";
                                            id = "heimdall-load";
                                            type = "load";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 100;
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "Temperature";
                                            id = "heimdall-temperature";
                                            type = "temperature";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 80;
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "Interrupts";
                                            id = "heimdall-interrupts";
                                            type = "interrupts";
                                            interval = "1m";
                                            warning = 20000;
                                            threshold = 50000;
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "Processes";
                                            id = "heimdall-processes";
                                            type = "processes";
                                            interval = "30s";
                                            max_processes = 20;
                                            grid_col_span = 2;
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Memory";
                                    id = "heimdall-memory";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Usage";
                                            id = "heimdall-memory-usage";
                                            type = "memory";
                                            interval = "1m";
                                            warning = 90;
                                            threshold = 95;
                                            agent = "heimdall";
                                        }
                                        {
                                            # An OOM kill is an event, not a level: memory is back to normal
                                            # before the next sample, so the usage monitor beside this one cannot
                                            # see it. The counter read each cycle means no kill is ever missed,
                                            # and over this host's agent the module also follows the kernel
                                            # journal, so a kill is reported the moment it happens and names the
                                            # process the counter can only total.
                                            name = "OOM Kills";
                                            id = "heimdall-oom";
                                            type = "oom";
                                            interval = "1m";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Storage";
                                    id = "heimdall-storage";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Disk I/O";
                                            id = "heimdall-disk-io";
                                            type = "disk_io";
                                            interval = "30s";
                                            agent = "heimdall";
                                        }
                                        {
                                            # smartctl is slow and rarely changes its answer, so this reads hourly.
                                            name = "SMART";
                                            id = "heimdall-smart";
                                            type = "smart";
                                            interval = "1h";
                                            agent = "heimdall";
                                        }
                                        {
                                            # A pool changes state slowly and `zpool status` walks every vdev.
                                            name = "ZFS";
                                            id = "heimdall-zfs";
                                            type = "zfs";
                                            interval = "1h";
                                            warning = 90;
                                            threshold = 96;
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "/";
                                            id = "heimdall-disk-root";
                                            type = "disk_space";
                                            path = "/";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "/Storage";
                                            id = "heimdall-disk-storage";
                                            type = "disk_space";
                                            path = "/Storage";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "/boot";
                                            id = "heimdall-disk-boot";
                                            type = "disk_space";
                                            path = "/boot";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "heimdall";
                                        }
                                        {
                                            # Auto-discovers every mount, so it also covers filesystems not listed
                                            # explicitly above. Catches read-only remounts (which leave df reporting
                                            # healthy usage forever) and inode exhaustion.
                                            name = "Filesystems";
                                            id = "heimdall-filesystems";
                                            type = "filesystems";
                                            interval = "10m";
                                            warning = 90;
                                            threshold = 96;
                                            inode_warning = 85;
                                            inode_threshold = 95;
                                            grid_col_span = 2;
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Network";
                                    id = "heimdall-network";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Throughput";
                                            id = "heimdall-throughput";
                                            type = "throughput";
                                            interval = "30s";
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "Connections";
                                            id = "heimdall-connections";
                                            type = "connections";
                                            interval = "1m";
                                            warning = 500;
                                            threshold = 1000;
                                            agent = "heimdall";
                                        }
                                        {
                                            # nginx fronts every web service on Heimdall; probe the local front
                                            # door plus a few representative app URLs.
                                            name = "Service Reachability";
                                            id = "heimdall-ports";
                                            type = "ports";
                                            interval = "1m";
                                            timeout = 5;
                                            grid_col_span = 2;
                                            checks = [
                                                { name = "Nginx"; host = "localhost"; port = 443; }
                                                { name = "Home Assistant"; url = "https://home-assistant.heimdall.technet"; }
                                                { name = "Pi-hole"; url = "https://pi-hole.heimdall.technet"; }
                                                { name = "Homepage"; url = "https://homepage.heimdall.technet"; }
                                                { name = "Jackett"; url = "https://jackett.heimdall.technet"; }
                                            ];
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                            ];
                        }
                        {
                            name = "Running Services";
                            # Explicit id: a group id defaults to its name and every host has this group, so all three would share one key.
                            id = "heimdall-services";
                            type = "group";
                            children = [
                                {
                                    # Vigil watching itself. Runs in-process on Heimdall rather
                                    # than through a transport, so it names no agent.
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
                                    name = "NixOS Upgrade";
                                    id = "heimdall-svc-nixos-upgrade";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-nixos-upgrade";
                                            type = "systemd_service";
                                            interval = "1h";
                                            service_name = "nixos-upgrade.service";
                                            max_age = "1w";
                                            agent = "heimdall";
                                        }
                                        {
                                            name = "Deployment";
                                            id = "heimdall-nixos-deployment";
                                            type = "nixos_upgrade";
                                            interval = "5m";
                                            flake = upgradeFlake;
                                            eval_interval = "6h";
                                            rebuild_args = [ "--no-write-lock-file" "-L" ];
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Stremio Export";
                                    id = "heimdall-svc-stremio-export";
                                    type = "group";
                                    children = [
                                        {
                                            # Timer-driven oneshot (OnCalendar=daily). Monitored
                                            # in oneshot mode so a job that silently stops firing
                                            # is caught by max_age — a plain is-active check would
                                            # read "inactive" as healthy between runs.
                                            name = "Service";
                                            id = "heimdall-stremio-export";
                                            type = "systemd_service";
                                            interval = "1h";
                                            service_name = "stremio-export.service";
                                            max_age = "2d";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Mosquitto";
                                    id = "heimdall-svc-mosquitto";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-mosquitto";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "mosquitto.service";
                                            agent = "heimdall";
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
                                            # user (mosquitto/broker.nix) scoped by ACL to
                                            # vigil/probe/# only.
                                            name = "Delivery";
                                            id = "heimdall-mosquitto-delivery";
                                            type = "mosquitto";
                                            interval = "5m";
                                            host = "127.0.0.1";
                                            port = 1883;
                                            username = "vigil";
                                            password_command = "cat /run/secrets/mosquitto_vigil_password";
                                            probe_topic = "vigil/probe/heimdall-mosquitto-delivery";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Calibre Web";
                                    id = "heimdall-svc-calibre-web";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-calibre-web";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "calibre-web-automated.service";
                                            agent = "heimdall";
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
                                            name = "Library";
                                            id = "heimdall-calibre-web-library";
                                            type = "http";
                                            interval = "10m";
                                            url = "http://127.0.0.1:8083/opds";
                                            username = "vigil";
                                            password_command = "cat /run/secrets/calibre_web_vigil_password";
                                            check_title = "OPDS FEED";
                                            expect = {
                                                body_contains = "<feed";
                                                body_contains_any = [ "atom" "opds" ];
                                            };
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Unbound";
                                    id = "heimdall-svc-unbound";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-unbound";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "unbound.service";
                                            agent = "heimdall";
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
                                            name = "Resolution";
                                            id = "heimdall-unbound-resolution";
                                            type = "unbound";
                                            interval = "5m";
                                            query_host = "127.0.0.1";
                                            query_port = 5335;
                                            query_domain = "cloudflare.com";
                                            servfail_warning = 5;
                                            servfail_threshold = 20;
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "VLC";
                                    id = "heimdall-svc-vlc";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-vlc";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "vlc-audio.service";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Nginx";
                                    id = "heimdall-svc-nginx";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-nginx";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "nginx.service";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Pi-hole";
                                    id = "heimdall-svc-pihole";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-pihole";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "pihole-ftl.service";
                                            agent = "heimdall";
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
                                            name = "DNS";
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
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Home Assistant";
                                    id = "heimdall-svc-home-assistant";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-home-assistant";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "home-assistant.service";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Frigate";
                                    id = "heimdall-svc-frigate";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-frigate";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "frigate.service";
                                            agent = "heimdall";
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
                                            name = "Cameras";
                                            id = "heimdall-frigate-cameras";
                                            type = "frigate";
                                            interval = "1m";
                                            api_url = "http://127.0.0.1:5000";
                                            agent = "heimdall";
                                        }
                                        {
                                            # The broker leg, which neither monitor above
                                            # covers: Frigate can be running, and its API
                                            # answering, while its MQTT session is gone --
                                            # Home Assistant then stops seeing events and
                                            # everything else stays green.
                                            #
                                            # frigate/available is retained and carries
                                            # Frigate's last will, so the broker's own
                                            # view of the session answers immediately:
                                            # "online" was published on connect, "offline"
                                            # is what the broker publishes on an unclean
                                            # disconnect, and nothing at all means Frigate
                                            # has never connected since the broker's
                                            # persistence file was written. All three are
                                            # a non-zero exit here. Read from Frigate's
                                            # source (comms/mqtt.py) rather than assumed.
                                            #
                                            # Authenticates as the same `vigil` user as
                                            # the delivery probe, which for this needs
                                            # `read frigate/available` -- see
                                            # mosquitto/broker.nix.
                                            name = "MQTT";
                                            id = "heimdall-frigate-mqtt";
                                            type = "command";
                                            interval = "5m";
                                            timeout = 15;
                                            command = ''
                                                test "$(mosquitto_sub -h 127.0.0.1 -p 1883 \
                                                    -u vigil -P "$(cat /run/secrets/mosquitto_vigil_password)" \
                                                    -t frigate/available -C 1 -W 5)" = online
                                            '';
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "FreshRSS";
                                    id = "heimdall-svc-freshrss";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-freshrss";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "phpfpm-freshrss.service";
                                            agent = "heimdall";
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
                                            name = "Feeds";
                                            id = "heimdall-freshrss-feeds";
                                            type = "freshrss";
                                            interval = "15m";
                                            api_url = "http://freshrss.heimdall.technet";                    # nginx's catch-all drops requests to the bare IP with 444, so the FreshRSS vhost name is required
                                            username = "beatlink";
                                            api_password_command = "cat /run/secrets/freshrss_api_password";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "qBittorrent";
                                    id = "heimdall-svc-qbittorrent";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-qbittorrent";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "qbittorrent.service";
                                            agent = "heimdall";
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
                                            name = "Transfers";
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
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Openbooks";
                                    id = "heimdall-svc-openbooks";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-openbooks";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "openbooks.service";
                                            agent = "heimdall";
                                        }
                                        {
                                            # IRC-bridge health, as opposed to the
                                            # monitor above, which only proves the web
                                            # server is running. Opens one short-lived
                                            # WebSocket connection (websocat, installed
                                            # beside openbooks) to confirm the IRC
                                            # bridge to irc.irchighway.net is actually
                                            # connected — sends a connect request and
                                            # expects the success appearance in the
                                            # reply, then closes immediately since
                                            # OpenBooks serves only one client at a
                                            # time. 10m interval keeps this probe's
                                            # share of that single slot small.
                                            name = "IRC Bridge";
                                            id = "heimdall-openbooks-irc";
                                            type = "http";
                                            interval = "10m";
                                            url = "ws://127.0.0.1:9777/ws";
                                            body = ''{"type":1,"payload":{}}'';
                                            check_title = "IRC BRIDGE";
                                            expect = {
                                                body_contains = ''"appearance":1'';
                                            };
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                # Traccar is switched off: no tracker protocol was ever enabled, so it never had a device to watch.
                                /*
                                {
                                    name = "Traccar";
                                    id = "heimdall-svc-traccar";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-traccar";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "traccar.service";
                                            agent = "heimdall";
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
                                            name = "Devices";
                                            id = "heimdall-traccar-devices";
                                            type = "traccar";
                                            interval = "15m";
                                            api_url = "http://127.0.0.1:9280";
                                            username = "vigil";
                                            password_command = "cat /run/secrets/traccar_vigil_password";
                                            stale_warning = 24;
                                            stale_threshold = 72;
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                */
                                {
                                    name = "Jackett";
                                    id = "heimdall-svc-jackett";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-jackett";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "jackett.service";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "ESPHome";
                                    id = "heimdall-svc-esphome";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-esphome";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "esphome.service";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Homepage";
                                    id = "heimdall-svc-homepage";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-homepage";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "homepage-dashboard.service";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Blockurl";
                                    id = "heimdall-svc-blockurl";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-blockurl";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "blockurl.service";
                                            agent = "heimdall";
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
                                            name = "Database";
                                            id = "heimdall-blockurl-database";
                                            type = "blockurl";
                                            interval = "15m";
                                            api_url = "http://127.0.0.1:9001";
                                            api_key_command = "cut -d= -f2- /run/secrets/blockurl_api_key";
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Radicale";
                                    id = "heimdall-svc-radicale";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-radicale";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "radicale.service";
                                            agent = "heimdall";
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
                                            name = "WebDAV";
                                            id = "heimdall-radicale-webdav";
                                            type = "http";
                                            interval = "10m";
                                            url = "http://127.0.0.1:5232/";
                                            method = "PROPFIND";
                                            headers = {
                                                Depth = "0";
                                                "Content-Type" = "application/xml";
                                            };
                                            body = ''<?xml version="1.0"?><propfind xmlns="DAV:"><prop><current-user-principal/></prop></propfind>'';
                                            username = "vigil";
                                            password_command = "cat /run/secrets/radicale_vigil_password";
                                            check_title = "PROPFIND";
                                            expect = {
                                                status = 207;
                                            };
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Syncthing";
                                    id = "heimdall-svc-syncthing";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-syncthing";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "syncthing.service";
                                            agent = "heimdall";
                                        }
                                        {
                                            # Folder/device health, as opposed to the
                                            # monitor above, which only proves the
                                            # daemon is running. Reads Syncthing's own
                                            # REST API, keyed by an API key extracted
                                            # from config.xml by a small Nix-managed
                                            # timer (see syncthing.nix) rather than a
                                            # separately stored credential.
                                            name = "Sync Health";
                                            id = "heimdall-syncthing-health";
                                            type = "syncthing";
                                            interval = "10m";
                                            api_url = "http://127.0.0.1:8384";
                                            api_key_command = "cat /Storage/Services/Syncthing/vigil-api-key";
                                            devices = [ "Odin" "Ragnarok" ];                        # ThorX is the phone and roams by design, so its absence is not a health signal
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                                {
                                    name = "Trilium";
                                    id = "heimdall-svc-trilium";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "heimdall-trilium";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "trilium-server.service";
                                            agent = "heimdall";
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
                                            name = "Activity";
                                            id = "heimdall-trilium-activity";
                                            type = "trilium";
                                            interval = "1h";
                                            api_url = "http://127.0.0.1:8080";
                                            token_command = "cat /run/secrets/trilium_etapi_token";
                                            stale_warning = 72;
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                            ];
                        }
                        {
                            # Heimdall (the server) owns /Storage/Services, backed up by borgmatic
                            # only — there is no Vorta on the server.
                            name = "Backups";
                            # Explicit id: a group id defaults to its name and both backed-up hosts have this group, so they would share one key.
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
                                            agent = "heimdall";
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
                                            agent = "heimdall";
                                        }
                                    ];
                                }
                            ];
                        }
                    ];
                }
                {
                    name = "Odin";
                    id = "odin-host";
                    type = "group";
                    children = [
                        {
                            name = "Availability";
                            id = "odin";
                            type = "uptime";
                            target_host = "odin.technet";
                            interval = "30s";
                        }
                        {
                            name = "System Stats";
                            # Explicit id: a group id defaults to its name and every host has this group, so all three would share one key.
                            id = "odin-metrics";
                            type = "group";
                            children = [
                                {
                                    name = "Compute";
                                    id = "odin-compute";
                                    type = "group";
                                    children = [
                                        {
                                            name = "CPU";
                                            id = "odin-cpu";
                                            type = "cpu";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 85;
                                            agent = "odin";
                                        }
                                        {
                                            name = "Load";
                                            id = "odin-load";
                                            type = "load";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 100;
                                            agent = "odin";
                                        }
                                        {
                                            name = "Temperature";
                                            id = "odin-temperature";
                                            type = "temperature";
                                            interval = "1m";
                                            warning = 70;
                                            threshold = 80;
                                            agent = "odin";
                                        }
                                        {
                                            name = "Interrupts";
                                            id = "odin-interrupts";
                                            type = "interrupts";
                                            interval = "1m";
                                            warning = 20000;
                                            threshold = 50000;
                                            agent = "odin";
                                        }
                                        {
                                            # Odin's dGPU sleeps with the laptop lid and nvidia-smi can wedge
                                            # uninterruptibly when it does. The module suspends its own probe
                                            # after `timeout_trip` timeouts rather than stranding a process per
                                            # cycle, and reports offline (not failed) while suspended.
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
                                            agent = "odin";
                                        }
                                        {
                                            name = "Processes";
                                            id = "odin-processes";
                                            type = "processes";
                                            interval = "30s";
                                            max_processes = 20;
                                            grid_col_span = 2;
                                            agent = "odin";
                                        }
                                    ];
                                }
                                {
                                    name = "Memory";
                                    id = "odin-memory";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Usage";
                                            id = "odin-memory-usage";
                                            type = "memory";
                                            interval = "1m";
                                            warning = 90;
                                            threshold = 95;
                                            agent = "odin";
                                        }
                                        {
                                            # An OOM kill is an event, not a level: memory is back to normal
                                            # before the next sample, so the usage monitor beside this one cannot
                                            # see it. The counter read each cycle means no kill is ever missed,
                                            # and over this host's agent the module also follows the kernel
                                            # journal, so a kill is reported the moment it happens and names the
                                            # process the counter can only total.
                                            name = "OOM Kills";
                                            id = "odin-oom";
                                            type = "oom";
                                            interval = "1m";
                                            agent = "odin";
                                        }
                                    ];
                                }
                                {
                                    name = "Storage";
                                    id = "odin-storage";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Disk I/O";
                                            id = "odin-disk-io";
                                            type = "disk_io";
                                            interval = "30s";
                                            agent = "odin";
                                        }
                                        {
                                            # smartctl is slow and rarely changes its answer, so this reads hourly.
                                            name = "SMART";
                                            id = "odin-smart";
                                            type = "smart";
                                            interval = "1h";
                                            agent = "odin";
                                        }
                                        {
                                            # A pool changes state slowly and `zpool status` walks every vdev.
                                            name = "ZFS";
                                            id = "odin-zfs";
                                            type = "zfs";
                                            interval = "1h";
                                            warning = 90;
                                            threshold = 96;
                                            agent = "odin";
                                        }
                                        {
                                            name = "/";
                                            id = "odin-disk-root";
                                            type = "disk_space";
                                            path = "/";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "odin";
                                        }
                                        {
                                            name = "/Storage";
                                            id = "odin-disk-storage";
                                            type = "disk_space";
                                            path = "/Storage";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "odin";
                                        }
                                        {
                                            name = "/boot";
                                            id = "odin-disk-boot";
                                            type = "disk_space";
                                            path = "/boot";
                                            threshold = 90;
                                            interval = "10m";
                                            agent = "odin";
                                        }
                                        {
                                            # Auto-discovers every mount, so it also covers filesystems not listed
                                            # explicitly above. Catches read-only remounts (which leave df reporting
                                            # healthy usage forever) and inode exhaustion.
                                            name = "Filesystems";
                                            id = "odin-filesystems";
                                            type = "filesystems";
                                            interval = "10m";
                                            warning = 90;
                                            threshold = 96;
                                            inode_warning = 85;
                                            inode_threshold = 95;
                                            grid_col_span = 2;
                                            agent = "odin";
                                        }
                                    ];
                                }
                                {
                                    name = "Network";
                                    id = "odin-network";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Throughput";
                                            id = "odin-throughput";
                                            type = "throughput";
                                            interval = "30s";
                                            agent = "odin";
                                        }
                                        {
                                            name = "Connections";
                                            id = "odin-connections";
                                            type = "connections";
                                            interval = "1m";
                                            warning = 500;
                                            threshold = 1000;
                                            agent = "odin";
                                        }
                                        {
                                            name = "WiFi";
                                            id = "odin-wifi";
                                            type = "wifi";
                                            interval = "1m";
                                            quality_warning = 40;
                                            quality_threshold = 20;
                                            agent = "odin";
                                        }
                                    ];
                                }
                            ];
                        }
                        {
                            name = "Running Services";
                            # Explicit id: a group id defaults to its name and every host has this group, so all three would share one key.
                            id = "odin-services";
                            type = "group";
                            children = [
                                {
                                    name = "NixOS Upgrade";
                                    id = "odin-svc-nixos-upgrade";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "odin-nixos-upgrade";
                                            type = "systemd_service";
                                            interval = "1h";
                                            service_name = "nixos-upgrade.service";
                                            max_age = "1w";
                                            agent = "odin";
                                        }
                                        {
                                            name = "Deployment";
                                            id = "odin-nixos-deployment";
                                            type = "nixos_upgrade";
                                            interval = "5m";
                                            flake = upgradeFlake;
                                            eval_interval = "6h";
                                            rebuild_args = [ "--no-write-lock-file" "-L" ];
                                            agent = "odin";
                                        }
                                    ];
                                }
                                {
                                    name = "Networking";
                                    id = "odin-svc-networking";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "odin-networking";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "NetworkManager.service";
                                            agent = "odin";
                                        }
                                    ];
                                }
                                {
                                    name = "Bluetooth";
                                    id = "odin-svc-bluetooth";
                                    type = "group";
                                    children = [
                                        {
                                            name = "Service";
                                            id = "local-bluetooth";
                                            type = "systemd_service";
                                            interval = "1m";
                                            service_name = "bluetooth.service";
                                            agent = "odin";
                                        }
                                    ];
                                }
                            ];
                        }
                        {
                            # Odin (the laptop) owns /Storage. Vorta and borgmatic each keep their
                            # own repo set, so both appear here.
                            name = "Backups";
                            # Explicit id: a group id defaults to its name and both backed-up hosts have this group, so they would share one key.
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
                                            agent = "odin";
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
                                            agent = "odin";
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
                                            agent = "odin";
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
                                            agent = "odin";
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
                                            agent = "odin";
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
                                            agent = "odin";
                                        }
                                    ];
                                }
                            ];
                        }
                    ];
                }
                {
                    name = "Thor";
                    id = "thor-host";
                    type = "group";
                    children = [
                        {
                            name = "Availability";
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
        };
    };

    systemd.tmpfiles.settings."Vigil"."/Storage/Services/Vigil" = {
        d = {
            user = "vigil";
            group = "vigil";
            mode = "0750";
        };
        Z = {
            user = "vigil";
            group = "vigil";
            mode = "0750";
        };
    };

    # The agents' endpoint is served on the dashboard's own port, so Odin and
    # Ragnarok need to reach 9611 — over WireGuard only, the same mesh their SSH
    # collection already used. The port stays closed on every other interface;
    # browsers keep using the TLS vhost below.
    networking.firewall.interfaces."wireguard0".allowedTCPPorts = [ 9611 ];

    nginx-vhosts.vigil = {
        domain = "vigil.heimdall.technet";
        port = 9611;
    };
}
