# Vigil Agent ########################################################################################################################################
#
# Everything Vigil needs on a monitored host: the agent it collects through, the SSH login it falls back to, and the sudo rules both run under.
#
# The agent dials outward to Heimdall and holds one WebSocket open, carrying both the commands Vigil's monitors run here and the events it watches
# locally (journal follow, fast local sampling) and pushes the moment they happen. Nothing listens on this host: the agent opens no port and needs no
# key of its own.
#
# The `vigil-access` SSH login is no longer on the collection path. It stays configured as a fallback — an agent that cannot connect takes its host's
# monitors down with it, and re-adding SSH access to a host you can no longer see is the wrong order of operations. Remove it once the agents have
# proven themselves.
#
# The agent runs unprivileged as `vigil-agent`, with the same group memberships and the same scoped NOPASSWD sudo rules `vigil-access` has. Those
# rules do not become unnecessary under the agent — smartctl needs root either way — so the alternative to this list is a root daemon, which is worse.
#
{
    config,
    inputs,
    lib,
    pkgs,
    ...
}:
let
    agentHosts = [
        "Heimdall"
        "Odin"
        "Ragnarok"
        "Thor"
    ];
    host = config.networking.hostName;
    agentId = lib.toLower host;

    # Heimdall runs the Vigil server itself, so its own agent takes the short way round rather than depending on WireGuard being up to monitor itself.
    server = if host == "Heimdall" then "127.0.0.1" else "heimdall.technet";

    # sudoers ends a command spec at an unescaped colon.
    upgradeFlake = builtins.replaceStrings [ ":" ] [ "\\:" ] config.system.autoUpgrade.flake;

    # The scheduled collection's own arguments, so Vigil's button runs the run the timer runs.
    gcOptions = config.nix.gc.options;

    # A borg poll carries its deadline inside the sudo, so sudo matches `timeout` rather than `borg` and the plain borg rule below never fires. One spec
    # per digit count, because a `*` in place of the seconds would span the space after them and let any command follow.
    borgDeadlineRules =
        map
            (seconds: {
                command = "/run/current-system/sw/bin/timeout -k 5 ${seconds} borg *";
                options = [
                    "NOPASSWD"
                    "SETENV"
                ];
            })
            [
                "[0-9]"
                "[0-9][0-9]"
                "[0-9][0-9][0-9]"
                "[0-9][0-9][0-9][0-9]"
                "[0-9][0-9][0-9][0-9][0-9]"
            ];
in
{
    imports = [ inputs.vigil.nixosModules.agent ];

    config = lib.mkMerge [

        # Agent ######################################################################################################################################
        (lib.mkIf (builtins.elem host agentHosts) {

            # One file per agent, each encrypted to Heimdall (which declares every agent) plus the single host that agent runs on, so no host can
            # decrypt another's token. The .sops.yaml rules that carve these out of the fleet-wide 0-common rule must stay ahead of it — first match wins.
            sops.secrets.vigil_agent_token = {
                sopsFile = "${config.technet.secrets.commonPath}/vigil-agent-${agentId}.yaml";
                owner = "vigil-agent";
            };

            services.vigil-agent = {
                enable = true;
                url = "ws://${server}:9611/api/agent/ws";
                id = agentId;
                tokenFile = config.sops.secrets.vigil_agent_token.path;

                # Same memberships `vigil-access` holds, since the monitors run the same commands: borg repo reads for backup health, and the journal for
                # unit status and for the agent's own journal watchers.
                extraGroups = [
                    "borg"
                    "systemd-journal"
                    "vigil-monitor"
                ];

                # Monitors send plain shell, and over SSH they resolved against the host's system profile. Handing the agent that same profile keeps all 98
                # migrated monitors resolving exactly what they resolved before, rather than making each one's tools an explicit dependency here.
                path = [
                    "/run/current-system/sw"
                    pkgs.git # nix shells out to git to fetch git inputs while evaluating the flake
                    pkgs.nmap # The vuln_scan monitors sweep the other hosts from here
                ];
            };

            # Desktop Notifications ##################################################################################################################
            sops.secrets.vigil_agent_desktop_token = lib.mkIf (host == "Odin") {
                sopsFile = "${config.technet.secrets.commonPath}/vigil-agent-odin-desktop.yaml";
                key = "vigil_agent_token";
                owner = "beatlink";
            };

            services.vigil-agent.desktop = lib.mkIf (host == "Odin") {
                enable = true;
                id = "odin-desktop";
                tokenFile = config.sops.secrets.vigil_agent_desktop_token.path;
            };

            systemd.services.vigil-agent = {
                environment.HOME = "/var/lib/vigil-agent"; # nix and the detached job workdirs write under $HOME; the default /var/empty is immutable
                serviceConfig = {
                    StateDirectory = "vigil-agent";
                    CacheDirectory = "vigil-borg"; # Backs the borg monitors' cache_dir; without it each poll rebuilds the repo's chunks cache under mktemp and discards it
                    ProtectHome = lib.mkForce false; # true hides /home from borg source paths and makes /root read-only for the rebuild's nix cache

                    # Contention-only. A CPUQuota of 200% was here and had to go: it throttled the agent 679 times on Odin and 1625 on Heimdall, and every
                    # monitor command runs under a deadline, so starving this is how a healthy host starts reporting timeouts. What made the ceiling look
                    # necessary was borg polls that never terminated, and that was a Vigil bug -- an unprivileged agent cannot kill what sudo started, so
                    # the timeout it reported was never enforced. Fixed upstream in 64729f9; the deadline now sits inside the sudo.
                    Nice = 10;
                    CPUWeight = 40;
                };
            };
        })

        # SSH Fallback Login #########################################################################################################################
        {
            users = {
                groups."vigil-access" = { };

                # Read access to the credentials monitors `cat` on the target host (API tokens, service passwords). Held by both transports, because
                # which user runs that `cat` is exactly what changes between them.
                groups."vigil-monitor" = { };
                users."vigil-access" = {
                    isSystemUser = true;
                    description = "Vigil monitor (remote login account)";
                    group = "vigil-access";
                    shell = "/run/current-system/sw/bin/bash"; # borg and systemctl run over SSH exec, which needs a shell
                    extraGroups = [
                        "borg" # Read access to borg repos for backup health checks
                        "systemd-journal" # Read systemd service status and logs
                        "vigil-monitor" # Read the per-service credentials monitors cat on the target
                    ];
                    openssh.authorizedKeys.keys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6oDtIndxb2aJJFhl3+xU+4nuVUQQrzcWOLX+RslJU/ vigil@technet"
                    ];
                };
            };
        }

        # Sudo Scope #################################################################################################################################
        {
            security.sudo.extraRules = [
                {
                    users = [
                        "vigil-access" # SSH transport (fallback)
                        "vigil-agent" # Agent transport (primary)
                    ];
                    commands = [
                        # Never add the python3 heredoc helper, since sudoers matches argv rather than the script body and it would grant arbitrary root
                        {
                            command = "/run/current-system/sw/bin/systemctl start *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl stop *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl restart *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl enable *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl disable *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl daemon-reload";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl cat *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl status *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/systemctl show *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/smartctl -H *";
                            options = [ "NOPASSWD" ];
                        }
                        {
                            command = "/run/current-system/sw/bin/smartctl -H -d sat *";
                            options = [ "NOPASSWD" ];
                        }
                        # Covers the unbounded runs only — a poll arrives wrapped in a deadline and matches borgDeadlineRules instead
                        {
                            command = "/run/current-system/sw/bin/borg *";
                            options = [
                                "NOPASSWD"
                                "SETENV"
                            ];
                        }
                        # Vigil's nixos_upgrade action, matched argv for argv: changing the monitor's rebuild_args stops sudo matching this
                        {
                            command = "/run/current-system/sw/bin/nixos-rebuild switch --flake ${upgradeFlake} --no-write-lock-file -L --refresh";
                            options = [ "NOPASSWD" ];
                        }
                        # The same action from a monitor that names its configuration; sudoers reads a bare # as a comment
                        {
                            command = "/run/current-system/sw/bin/nixos-rebuild switch --flake ${upgradeFlake}\\#${config.networking.hostName} --no-write-lock-file -L --refresh";
                            options = [ "NOPASSWD" ];
                        }
                        # Vigil's nix_gc action, matched the same way: it collects with nix.gc.options and nothing else
                        {
                            command = "/run/current-system/sw/bin/nix-collect-garbage ${gcOptions}";
                            options = [ "NOPASSWD" ];
                        }
                    ]
                    ++ borgDeadlineRules;
                }
            ];
        }
    ];
}
