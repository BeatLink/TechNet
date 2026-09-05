# Vigil Agent ########################################################################################################################################
#
# The companion daemon Vigil reaches this host through. It dials outward to Heimdall and holds one WebSocket open, carrying both the commands Vigil's
# monitors run here and the events it watches locally (journal follow, fast local sampling) and pushes the moment they happen.
#
# Nothing listens on this host: the agent opens no port and needs no key of its own, so the inbound `vigil-access` SSH login is no longer on the
# collection path. That login stays configured for now as a fallback while the migration settles — see vigil-access.nix.
#
# Runs unprivileged as `vigil-agent`, with the same group memberships and the same scoped NOPASSWD sudo rules `vigil-access` had. Running it as root
# would be the easy way to drop those rules; the rules are the narrower grant, so they stay.
#
{
    config,
    inputs,
    lib,
    pkgs,
    ...
}:
let
    # Thor is a phone: Vigil only pings it, so it has no commands to run and no agent token.
    agentHosts = [ "Heimdall" "Odin" "Ragnarok" ];
    host = config.networking.hostName;
    agentId = lib.toLower host;

    # Heimdall runs the Vigil server itself, so its own agent takes the short way round rather than depending on WireGuard being up to monitor itself.
    server = if host == "Heimdall" then "127.0.0.1" else "heimdall.technet";
in
{
    imports = [ inputs.vigil.nixosModules.agent ];

    config = lib.mkIf (builtins.elem host agentHosts) {

        # Token ######################################################################################################################################
        #
        # One file per agent, each encrypted to Heimdall (which declares every agent) plus the single host that agent runs on, so no host can decrypt
        # another's token. The .sops.yaml rules that carve these out of the fleet-wide 0-common rule must stay ahead of it — first match wins.
        #
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
                pkgs.git                                                    # nix shells out to git to fetch git inputs while evaluating the flake
            ];
        };

        systemd.services.vigil-agent = {
            environment.HOME = "/var/lib/vigil-agent";                     # nix and the detached job workdirs write under $HOME; the default /var/empty is immutable
            serviceConfig = {
                StateDirectory = "vigil-agent";
                ProtectHome = lib.mkForce false;                            # true hides /home from borg source paths and makes /root read-only for the rebuild's nix cache
            };
        };
    };
}
