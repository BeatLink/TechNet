# Vigil Access #######################################################################################################################################
#
# Unprivileged account the Vigil monitor on Heimdall SSHes into on every host, and the scoped sudo rule its plugins run through.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Remote Login Account #######################################################################################################################
        {
            users = {
                groups."vigil-access" = { };
                users."vigil-access" = {
                    isSystemUser = true;
                    description = "Vigil monitor (remote login account)";
                    group = "vigil-access";
                    shell = "/run/current-system/sw/bin/bash";                  # borg and systemctl run over SSH exec, which needs a shell
                    extraGroups = [
                        "borg"                                                  # Read access to borg repos for backup health checks
                        "systemd-journal"                                       # Read systemd service status and logs
                        "blockurl"                                              # Read blockurl_api_key for the blockurl monitor
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
                    users = [ "vigil-access" ];
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
                    ];
                }
            ];
        }
    ];
}
