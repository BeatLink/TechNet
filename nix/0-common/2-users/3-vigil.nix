# Vigil Access
#
# Dedicated, unprivileged login account for the Vigil monitor to SSH into every
# host as (agentless monitoring). Vigil runs on Heimdall and connects to this
# account on each target to read metrics, systemd service status and borg
# backup health.
#
# This is the *remote* account Vigil logs into (`vigil-access`), kept separate
# from the `vigil` service user that the services.vigil module creates on
# Heimdall.
#
# Only the *public* key lives here. The matching private key stays on Heimdall
# alone (secrets/2-server/vigil.yaml), because Vigil is the only thing that
# uses it — to log in here. A Vigil-triggered backup runs `borg create` on this
# host, but borg's own hop to the repo server authenticates with THIS host's
# existing borg key (Vorta's or borgmatic's), not Vigil's, so no Vigil private
# key is needed on the monitored hosts.
#
# Root command access (systemctl/smartctl/borg) is granted via a scoped sudo
# rule, not `wheel` — see 4-vigil-sudo.nix.
#

{
    users = {
        groups."vigil-access" = { };
        users."vigil-access" = {
            isSystemUser = true;               # Service account, no interactive desktop login
            description = "Vigil monitor (remote login account)";
            group = "vigil-access";
            shell = "/run/current-system/sw/bin/bash";  # borg / systemctl are run over SSH exec, needs a shell
            extraGroups = [
                "borg"                          # Read access to borg repos for backup health checks
                "systemd-journal"               # Read systemd service status / logs
            ];
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6oDtIndxb2aJJFhl3+xU+4nuVUQQrzcWOLX+RslJU/ vigil@technet"
            ];
        };
    };
}
