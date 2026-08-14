# Waypipe ############################################################################################################################################
#
# Runs Wayland applications from another host inside one shared session per host, so they share a bus, a portal stack and this host's speakers.
#
# waypipe-desktop owns the sessions, launchers and options; this module supplies the pair of hosts, their key and the apps they trade.
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

    thorToOdin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/XKqcENe9Q3RMEdy20Oszf5jttKCZVGGqkMB255Sy waypipe-thor-to-odin";
    odinToThor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAqNicedrY/ZIabItsYp9G72eYwpHFNkzaN3RLaka5MO waypipe-odin-to-thor";

    isOdin = config.networking.hostName == "Odin";
    peer = if isOdin then "thor" else "odin";
in
{
    imports = [ inputs.waypipe-desktop.nixosModules.default ];

    options.technet.waypipe = {
        enable = lib.mkEnableOption "waypipe remote application launchers"; # Off by default because sops needs a waypipe.yaml under the host's secrets directory

        # Forwarded verbatim, so waypipe-desktop's own module stays the one place these are described
        apps = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "Applications run on another host and displayed on this one, as programs.waypipe-desktop.apps definitions.";
        };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
        # Package ------------------------------------------------------------------------------------------------------------------------------------
        {
            nixpkgs.overlays = [
                inputs.waypipe-desktop.overlays.default # Rebuilds the wrapper against the waypipe below, which its own flake output would miss
                (final: prev: {
                    waypipe = prev.waypipe.overrideAttrs (old: {
                        # Drop when waypipe supports ffmpeg 9; 0.11.0 reads AVVulkanDeviceContext fields it no longer has and fails to compile
                        mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dwith_video=disabled" ];
                    });
                })
            ];
        }

        # Launchers ----------------------------------------------------------------------------------------------------------------------------------
        {
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
        }

        # Access -------------------------------------------------------------------------------------------------------------------------------------
        {
            sops.secrets.waypipe_key = {
                sopsFile = "${config.technet.secrets.path}/waypipe.yaml";
                owner = "beatlink";
            };

            # Both hosts run each other's apps, so each is also the far side of the other's sessions
            services.waypipe-desktop = {
                enable = true;
                user = "beatlink";
                authorizedKeys = [ (if isOdin then thorToOdin else odinToThor) ];
            };

            # A dedicated alias, so the waypipe key never displaces the agent key on a plain `ssh odin`
            programs.ssh.extraConfig = ''

                Host ${peer}-waypipe
                    HostName ${peer}.technet
                    User beatlink
                    IdentityFile ${config.sops.secrets.waypipe_key.path}
                    IdentitiesOnly yes
            '';
        }
    ]);
}
