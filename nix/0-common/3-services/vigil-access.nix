# Vigil Access #######################################################################################################################################
#
# Unprivileged account the Vigil monitor on Heimdall SSHes into on every host, and the scoped sudo rule its plugins run through.
#
# Collection no longer goes through this login: monitors reach these hosts through the Vigil agent instead (see vigil-agent.nix). The account stays
# configured as a fallback — an agent that cannot connect takes its host's monitors down with it, and re-adding SSH access to a host you can no longer
# see is the wrong order of operations. Remove it once the agents have proven themselves.
#
# The sudo rule is shared by both: it is the privilege grant itself, and it is scoped the same way whichever transport runs the command. The agent
# does not make these unnecessary — smartctl needs root either way — so the alternative to this list is a root daemon, which is worse.
#

{ config, lib, ... }:
let
    # sudoers ends a command spec at an unescaped colon.
    upgradeFlake = builtins.replaceStrings [ ":" ] [ "\\:" ] config.system.autoUpgrade.flake;
in
{
    config = lib.mkMerge [

        # Remote Login Account #######################################################################################################################
        {
            users = {
                groups."vigil-access" = { };

                # Read access to the credentials monitors `cat` on the target host (API tokens, service passwords). Held by both transports, because
                # which user runs that `cat` is exactly what changes between them — see vigil-agent.nix.
                groups."vigil-monitor" = { };
                users."vigil-access" = {
                    isSystemUser = true;
                    description = "Vigil monitor (remote login account)";
                    group = "vigil-access";
                    shell = "/run/current-system/sw/bin/bash";                  # borg and systemctl run over SSH exec, which needs a shell
                    extraGroups = [
                        "borg"                                                  # Read access to borg repos for backup health checks
                        "systemd-journal"                                       # Read systemd service status and logs
                        "blockurl"                                              # Read blockurl_api_key for the blockurl monitor
                        "vigil-monitor"                                         # Read the per-service credentials monitors cat on the target
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
                        "vigil-access"                                          # SSH transport (fallback)
                        "vigil-agent"                                           # Agent transport (primary)
                    ];
                    commands = [                                                # Never add the python3 heredoc helper, since sudoers matches argv rather than the script body and it would grant arbitrary root
                        { command = "/run/current-system/sw/bin/systemctl start *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl stop *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl restart *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl enable *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl disable *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl daemon-reload"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl cat *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl status *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/systemctl show *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/smartctl -H *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/smartctl -H -d sat *"; options = [ "NOPASSWD" ]; }
                        { command = "/run/current-system/sw/bin/borg *"; options = [ "NOPASSWD" "SETENV" ]; }
                        # Vigil's nixos_upgrade action, matched argv for argv: changing the monitor's rebuild_args stops sudo matching this
                        { command = "/run/current-system/sw/bin/nixos-rebuild switch --flake ${upgradeFlake} --no-write-lock-file -L --refresh"; options = [ "NOPASSWD" ]; }
                    ];
                }
            ];
        }
    ];
}
