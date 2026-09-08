# Waypipe ############################################################################################################################################
#
# Runs Wayland applications from another host inside one shared session per host, so they share a bus, a portal stack and this host's speakers.
#
# waypipe-desktop owns the sessions, launchers and options; this module supplies the two roles, their key and the apps they trade.
#
# The roles are separate options rather than one enable, because they need different things: a host that only displays needs a client key and an ssh
# alias, and a host that only runs the applications needs an sshd and the other side's public key. Thor displays; Heimdall runs.
#
{
    config,
    lib,
    inputs,
    pkgs,
    ...
}:
let
    cfg = config.technet.waypipe;

    thorToHeimdall = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVJQ2vYs4+U7rJz4COohgtzTa5k/wXNOtJpX7k6YUjg waypipe-thor-to-heimdall";
in
{
    imports = [ inputs.waypipe-desktop.nixosModules.default ];

    options.technet.waypipe = {
        enable = lib.mkEnableOption "waypipe remote application launchers"; # Off by default because sops needs a waypipe.yaml under the host's secrets directory

        serve = lib.mkEnableOption "running this host's applications on another host's screen";

        # Forwarded verbatim, so waypipe-desktop's own module stays the one place these are described
        apps = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "Applications run on another host and displayed on this one, as programs.waypipe-desktop.apps definitions.";
        };
    };

    config = lib.mkMerge [
        # Package ------------------------------------------------------------------------------------------------------------------------------------
        (lib.mkIf (cfg.enable || cfg.serve) {
            nixpkgs.overlays = [
                inputs.waypipe-desktop.overlays.default # Rebuilds the wrapper against the waypipe below, which its own flake output would miss
                (final: prev: {
                    waypipe = prev.waypipe.overrideAttrs (old: {
                        # Drop when waypipe supports ffmpeg 9; 0.11.0 reads AVVulkanDeviceContext fields it no longer has and fails to compile
                        mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dwith_video=disabled" ];
                    });
                })
            ];
        })

        # Launchers ----------------------------------------------------------------------------------------------------------------------------------
        (lib.mkIf cfg.enable {
            home-manager.users.beatlink = {
                imports = [ inputs.waypipe-desktop.homeModules.default ];

                programs.waypipe-desktop = {
                    enable = true;
                    inherit (cfg) apps;
                    package = pkgs.waypipe-desktop; # The overlay build, so the wrapper picks up the patched waypipe off this host's package set

                    # Declared rather than left to the tool's runtime hostname, so the sockets keep their names if this host ever gains a domain
                    sessionName = lib.toLower config.networking.hostName;
                };
            };
        })

        # Reaching the far side ----------------------------------------------------------------------------------------------------------------------
        (lib.mkIf cfg.enable {
            sops.secrets.waypipe_key = {
                sopsFile = "${config.technet.secrets.path}/waypipe.yaml";
                owner = "beatlink";
            };

            # A dedicated alias, so the waypipe key never displaces the agent key on a plain `ssh heimdall`
            programs.ssh.extraConfig = ''

                # heimdall.lan and heimdall.technet resolve to one address, the tunnel's, so there is no second path worth probing for
                Host heimdall-waypipe
                    HostName heimdall.technet
                    User beatlink
                    IdentityFile ${config.sops.secrets.waypipe_key.path}
                    IdentitiesOnly yes
            '';
        })

        # Letting the near side in -------------------------------------------------------------------------------------------------------------------
        (lib.mkIf cfg.serve {
            services.waypipe-desktop = {
                enable = true;
                user = "beatlink";
                authorizedKeys = [ thorToHeimdall ];
            };
        })
    ];
}
