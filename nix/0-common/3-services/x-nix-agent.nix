# X-Nix Agent ########################################################################################################################################
#
# The agent X-Nix on Heimdall reads, switches, collects and reboots this host through. It dials out to Heimdall over one WebSocket and signs in with its
# own ed25519 key, whose private half lives only in this host's x-nix-agent.yaml. It switches this host from the Attic cache with the closure X-Nix
# evaluated and built, and the module carries the sudo rules for that. On Odin it also builds and pushes the TechNet cache whenever Odin is up. Heimdall
# runs X-Nix itself and needs no agent.
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

    # Where the TechNet cache roots each build, the same folder as on Heimdall (x-nix.nix).
    buildRoots = "/var/lib/x-nix-build-roots";
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
            };
        };

        # The TechNet cache builds on Odin whenever it is up, so its agent roots the builds and pushes them with this host's Attic token.
        sops.secrets.attic_push_token = lib.mkIf (host == "Odin") {
            group = "x-nix-agent";
            mode = "0440";
        };

        systemd.tmpfiles.settings."X-Nix Agent" = lib.mkIf (host == "Odin") {
            ${buildRoots}.d = {
                user = "x-nix-agent";
                group = "x-nix-agent";
                mode = "0755";
            };
        };

        environment.persistence."/persistent".directories = lib.mkIf (host == "Odin") [
            {
                directory = buildRoots;
                user = "x-nix-agent";
                group = "x-nix-agent";
                mode = "0755";
            }
        ];
    };
}
