# X-Nix Agent ########################################################################################################################################
#
# The agent X-Nix on Heimdall reads, switches, collects and reboots this host through. It dials out to Heimdall over one WebSocket and signs in with its
# own ed25519 key, whose private half lives only in this host's x-nix-agent.yaml. It switches this host from the Attic cache with the closure X-Nix
# evaluated and built, and the module carries the sudo rules for that. On Heimdall it dials X-Nix on the same machine, so X-Nix itself runs nothing
# as root, and it runs Heimdall's jobs: flake updates, every build of the TechNet cache, and installs.
#
{
    config,
    inputs,
    lib,
    pkgs,
    ...
}:
let
    host = config.networking.hostName;

    agentHosts = [
        "Heimdall"
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
            url =
                if host == "Heimdall" then
                    "ws://127.0.0.1:7720/api/agent"
                else
                    "wss://nix.heimdall.technet/api/agent";
            keyFile = config.sops.secrets.x_nix_agent_key.path;
            # The checks and commands a switch runs here, which X-Nix on Heimdall names in x-nix.nix but never sends as text.
            switchCommands = {
                preSwitchChecks = lib.optionalAttrs (host == "Heimdall") {
                    boot-space = "test \"$(df --output=pcent /boot | tail -1 | tr -dc 0-9)\" -lt 90";
                };
                healthCommands = {
                    sshd = "systemctl is-active --quiet sshd.service";
                }
                // lib.optionalAttrs (host == "Heimdall") {
                    nginx = "systemctl is-active --quiet nginx.service";
                    atticd = "systemctl is-active --quiet atticd.service";
                }
                // lib.optionalAttrs (host == "Thor") {
                    phosh = "systemctl is-active --quiet phosh.service";
                };
                postSwitch = lib.optionalAttrs (host == "Thor") {
                    phosh = "systemctl is-active -q phosh.service || systemctl restart phosh.service";
                };
            };
            # The agent refuses a server that does not sign with this key, Heimdall's x-nix-server-key.yaml; a rotation lists the new line beside this one first.
            serverPublicKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJt/w3UoBWUZ16g4i7miu7FYY2aiujPJhBd98TGwNlBX x-nix-server" ];
            # Deploys from GitHub by itself once Heimdall has been gone half a day; only the laptop can evaluate the flake in reasonable time.
            pull = lib.mkIf (host == "Odin") {
                enable = true;
                remotes = [
                    {
                        url = "https://github.com/BeatLink/TechNet.git";
                        branch = "main";
                    }
                ];
                after = "12h";
                configuration = host;
                rebuildArgs = [ "--no-write-lock-file" ];
                allowedSignersFile = ./allowed-signers;
            };
        };
    };
}
