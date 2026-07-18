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
# The matching *private* key is also provisioned here, on every host, because a
# Vigil-triggered backup runs `borg create` on the host owning the source data
# and pushes to an ssh:// repo on a borg server. That onward hop authenticates
# as this key, so the source host needs it locally — Heimdall holding it is not
# enough. It is deployed root-owned (0400): borg runs under `sudo -n`, so root
# is the identity that reads it, and no unprivileged account should.
#
# Heimdall additionally declares this secret vigil-owned in its own vigil.nix,
# for the Vigil daemon's own outbound SSH; sops-nix merges the two declarations.
#

{ inputs, ... }:
{
    sops.secrets.vigil_ssh_key = {
        sopsFile = "${inputs.self}/secrets/0-common/vigil.yaml";
        mode = "0400";
    };

    users = {
        groups."vigil-access" = { };
        users."vigil-access" = {
            isSystemUser = true;               # Service account, no interactive desktop login
            description = "Vigil monitor (remote login account)";
            group = "vigil-access";
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
