# Vigil
#
# Dedicated, unprivileged login account for the Vigil monitor to SSH into every
# host as (agentless monitoring). Vigil runs on Heimdall and connects to this
# account on each target to read metrics, systemd service status and borg
# backup health.
#
# This is the *remote* account Vigil logs into. The Vigil *service* user on
# Heimdall is created separately by the services.vigil module.
#

{
    users = {
        groups."vigil" = { };
        users."vigil" = {
            isSystemUser = true;               # Service account, no login shell needed for interactive use
            description = "Vigil monitor (remote login account)";
            group = "vigil";
            shell = "/run/current-system/sw/bin/bash";  # borg / systemctl are run over SSH exec, needs a shell
            extraGroups = [
                "wheel"                         # Passwordless sudo (wheelNeedsPassword = false) for control actions, e.g. restarting services
                "borg"                          # Read access to borg repos for backup health checks
                "systemd-journal"               # Read systemd service status / logs
            ];
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6oDtIndxb2aJJFhl3+xU+4nuVUQQrzcWOLX+RslJU/ vigil@technet"
            ];
        };
    };
}
