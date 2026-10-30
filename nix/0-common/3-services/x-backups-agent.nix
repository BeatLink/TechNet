# X-Backups Agent ####################################################################################################################################
#
# The agent X-Backups runs its borg commands through on a host whose repositories it watches. It dials out to Heimdall and holds one WebSocket open, so
# nothing listens here. It signs in with its own ed25519 key, whose private half lives only in this host's x-backups-agent.yaml; Heimdall checks it
# against the public key declared in x-backups.nix.
#
# The agent runs unprivileged as `x-backups-agent`. Every borg call arrives as `sudo -n VAR=... borg ...`, with flock, systemd-inhibit, nice and ionice
# outside the sudo, so a single borg rule with SETENV is all the root it gets.
#
{
    config,
    inputs,
    lib,
    ...
}:
let
    host = config.networking.hostName;

    # The name each host has in X-Backups' config, which the agent must sign in as.
    agentNames = {
        Heimdall = "heimdall.technet";
        Odin = "odin.technet";
    };

    # Heimdall runs the server itself, so its own agent takes the short way round rather than depending on WireGuard being up.
    url = if host == "Heimdall" then "ws://127.0.0.1:7710/api/agent" else "wss://backups.heimdall.technet/api/agent";
in
{
    imports = [ inputs.x-backups.nixosModules.agent ];

    config = lib.mkIf (agentNames ? ${host}) {
        sops.secrets.x_backups_agent_key = {
            sopsFile = "${config.technet.secrets.path}/x-backups-agent.yaml";
            owner = "x-backups-agent";
        };

        services.x-backups-agent = {
            enable = true;
            inherit url;
            host = agentNames.${host};
            keyFile = config.sops.secrets.x_backups_agent_key.path;
            # Shares X-Monitor's job lock, so the two never run borg jobs on one host at once
            extraGroups = [ "borg-job-lock" ];
            # sudo resolves `borg` on this PATH, and the sudo rule below names the system profile's borg
            path = [ "/run/current-system/sw" ];
        };

        security.sudo.extraRules = [
            {
                users = [ "x-backups-agent" ];
                commands = [
                    {
                        command = "/run/current-system/sw/bin/borg *";
                        options = [
                            "NOPASSWD"
                            "SETENV"
                        ];
                    }
                ];
            }
        ];
    };
}
