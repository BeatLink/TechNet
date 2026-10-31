# X-Nix Agent ########################################################################################################################################
#
# The agent X-Nix on Heimdall reads, collects and reboots this host through. It dials out to Heimdall and holds one WebSocket open, so nothing listens
# here. It signs in with its own ed25519 key, whose private half lives only in this host's x-nix-agent.yaml; Heimdall checks it against the public key
# declared in x-nix.nix. Heimdall runs X-Nix itself and needs no agent.
#
# The agent runs unprivileged as `x-nix-agent`. Switching stays with X-Monitor, which deploys these hosts from Heimdall over SSH, so the sudo rules
# below cover only what X-Nix does on the host itself.
#
{
    config,
    inputs,
    lib,
    ...
}:
let
    host = config.networking.hostName;

    agentHosts = [
        "Odin"
        "Ragnarok"
        "Thor"
    ];
in
{
    imports = [ inputs.x-nix.nixosModules.agent ];

    config = lib.mkIf (builtins.elem host agentHosts) {
        sops.secrets.x_nix_agent_key = {
            sopsFile = "${config.technet.secrets.path}/x-nix-agent.yaml";
            owner = "x-nix-agent";
        };

        services.x-nix-agent = {
            enable = true;
            url = "wss://nix.heimdall.technet/api/agent";
            keyFile = config.sops.secrets.x_nix_agent_key.path;
        };

        security.sudo.extraRules = [
            {
                users = [ "x-nix-agent" ];
                commands = [
                    {
                        command = "/run/current-system/sw/bin/systemctl reboot";
                        options = [ "NOPASSWD" ];
                    }
                    # Collect Garbage runs the same collection the weekly timer does.
                    {
                        command = "/run/current-system/sw/bin/nix-collect-garbage ${config.nix.gc.options}";
                        options = [ "NOPASSWD" ];
                    }
                    # The Boot page reads systemd-boot's entries from the root-only /boot, and sets the one-shot next entry.
                    {
                        command = "/run/current-system/sw/bin/bootctl list --json=short";
                        options = [ "NOPASSWD" ];
                    }
                    {
                        command = "/run/current-system/sw/bin/bootctl set-oneshot *";
                        options = [ "NOPASSWD" ];
                    }
                ];
            }
        ];
    };
}
