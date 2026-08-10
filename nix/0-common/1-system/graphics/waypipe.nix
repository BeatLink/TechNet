# Waypipe ############################################################################################################################################
#
# Runs a Wayland application on another host and shows it here; each end authorises the other's key and holds its own half from sops.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.waypipe;

    thorToOdin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/XKqcENe9Q3RMEdy20Oszf5jttKCZVGGqkMB255Sy waypipe-thor-to-odin";
    odinToThor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAqNicedrY/ZIabItsYp9G72eYwpHFNkzaN3RLaka5MO waypipe-odin-to-thor";

    isOdin = config.networking.hostName == "Odin";
    peer = if isOdin then "thor" else "odin";

    appOptions =
        { name, ... }:
        {
            options = {
                title = lib.mkOption {
                    type = lib.types.str;
                    description = "Name shown in the app grid.";
                };

                host = lib.mkOption {
                    type = lib.types.str;
                    description = "SSH destination to run the application on, such as odin-waypipe.";
                };

                command = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    example = [
                        "firefox"
                        "--new-instance"
                    ];
                    description = "Argv of the remote program, resolved on the remote host's PATH.";
                };

                environment = lib.mkOption {
                    type = lib.types.attrsOf lib.types.str;
                    default = { };
                    description = "Environment variables set for the remote program.";
                };

                # A path, because the app is not installed here and so neither is its themed icon
                icon = lib.mkOption {
                    type = lib.types.either lib.types.str lib.types.path;
                    default = name;
                    description = "Icon file shipped beside the app's module, or a name from the local theme.";
                };

                categories = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ "Utility" ];
                    description = "Freedesktop categories for the launcher.";
                };

                extraFlags = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Waypipe flags for this app alone, appended after the shared ones.";
                };
            };
        };

    # `env` with no assignments is still a valid exec, so an app needing no variables needs no special case
    remoteArgv =
        app:
        [ "env" ] ++ lib.mapAttrsToList (n: v: "${n}=${v}") app.environment ++ app.command;

    launcher =
        key: app:
        pkgs.writeShellApplication {
            name = "waypipe-${key}";
            runtimeInputs = with pkgs; [
                openssh
                waypipe
            ];
            text = ''
                exec waypipe ${lib.escapeShellArgs (cfg.flags ++ app.extraFlags)} \
                    ssh ${lib.escapeShellArg app.host} ${lib.escapeShellArgs (remoteArgv app)}
            '';
        };

    desktopItem =
        key: app:
        pkgs.makeDesktopItem {
            name = "waypipe-${key}";
            desktopName = app.title;
            exec = "waypipe-${key}";
            icon = app.icon;
            categories = app.categories;
            terminal = false;
        };
in
{
    options.technet.waypipe = {
        enable = lib.mkEnableOption "waypipe remote application launchers"; # Off by default because sops needs a waypipe.yaml under the host's secrets directory

        flags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            # Measured on Odin->Thor: DMABUF costs 3x the CPU for fewer frames, and zstd beats lz4 because sshd is the scarcer resource
            default = [
                "--no-gpu"
                "--compress"
                "zstd=1"
            ];
            description = "Waypipe flags applied to every app, so tuning changes in one place.";
        };

        apps = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule appOptions);
            default = { };
            description = "Applications run on another host and displayed on this one.";
        };
    };

    config = lib.mkIf cfg.enable {
        home-manager.users.beatlink.home.packages =
            [ pkgs.waypipe ]
            ++ lib.flatten (lib.mapAttrsToList (key: app: [ (launcher key app) (desktopItem key app) ]) cfg.apps);

        sops.secrets.waypipe_key = {
            sopsFile = "${config.technet.secrets.path}/waypipe.yaml";
            owner = "beatlink";
        };

        users.users.beatlink.openssh.authorizedKeys.keys = [ (if isOdin then thorToOdin else odinToThor) ];

        # A dedicated alias, so the waypipe key never displaces the agent key on a plain `ssh odin`
        programs.ssh.extraConfig = ''

            Host ${peer}-waypipe
                HostName ${peer}.technet
                User beatlink
                IdentityFile ${config.sops.secrets.waypipe_key.path}
                IdentitiesOnly yes
        '';
    };
}
