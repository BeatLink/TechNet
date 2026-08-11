# Waypipe ############################################################################################################################################
#
# Runs Wayland applications from another host inside one shared session per host, so they share a bus, a portal stack and this host's speakers.
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

    # Named after this host, because the sockets sit in the remote host's /tmp beside any other display's
    session = lib.toLower config.networking.hostName;

    # Absolute paths under /tmp, so nothing here has to resolve the remote host's uid or runtime directory
    displaySocket = "/tmp/waypipe-${session}-display";
    busSocket = "/tmp/waypipe-${session}-bus";
    audioSocket = "/tmp/waypipe-${session}-audio";

    hosts = lib.unique (lib.mapAttrsToList (_: app: app.host) cfg.apps);
    unitName = host: "waypipe-session-${host}";

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

                audio = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Play the app's sound here rather than out of the remote host's speakers.";
                };

                audioLatency = lib.mkOption {
                    type = lib.types.nullOr lib.types.ints.positive;
                    default = null;
                    example = 400;
                    description = "Milliseconds of audio buffered ahead, trading delay for tolerance of a jittery link. Null leaves PipeWire's own default.";
                };
            };
        };

    # Every app joins the session's display and bus, which is what gives them one portal stack and one instance each
    remoteArgv =
        app:
        [
            "env"
            "WAYLAND_DISPLAY=${displaySocket}"
            "DBUS_SESSION_BUS_ADDRESS=unix:path=${busSocket}"
        ]
        ++ lib.optional app.audio "PULSE_SERVER=unix:${audioSocket}"
        ++ lib.optional (app.audioLatency != null) "PULSE_LATENCY_MSEC=${toString app.audioLatency}"
        ++ lib.mapAttrsToList (n: v: "${n}=${v}") app.environment
        ++ app.command;

    # Holds the remote end of one session open: the bus it serves is the process, so the display lives exactly as long as the link
    sessionLeader = pkgs.writeShellApplication {
        name = "waypipe-session-leader";
        runtimeInputs = with pkgs; [
            coreutils
            dbus
        ];
        text = ''
            # ssh runs no login shell, so without this dbus finds no portal service file and every portal call times out
            XDG_DATA_DIRS="$HOME/.nix-profile/share:/etc/profiles/per-user/$(id -un)/share:/run/current-system/sw/share"
            export XDG_DATA_DIRS

            # GDK would otherwise pick X11 and draw the portal's dialogs on this host's own screen
            export GDK_BACKEND=wayland

            rm -f "$1"

            # No --systemd-activation, so dbus spawns each portal from its Exec= line and the child inherits this session's display
            exec dbus-daemon --session --address="unix:path=$1" --nofork --nopidfile
        '';
    };

    # ServerAlive is what turns a dead link into a unit failure, rather than a session that hangs holding every window
    sessionRunner =
        host:
        pkgs.writeShellApplication {
            name = "waypipe-session-${host}";
            runtimeInputs = with pkgs; [
                openssh
                waypipe
            ];
            # The forward is left outside escapeShellArgs so XDG_RUNTIME_DIR still expands, which is what keeps the local uid out of this file
            text = ''
                # sshd does not reap the remote command when the link drops, and the sockets are removed below, so without this a restart
                # orphans the previous session's bus and strands every app still attached to it
                ssh -o BatchMode=yes ${lib.escapeShellArg host} ${
                    lib.escapeShellArg "pkill -f '^dbus-daemon --session --address=unix:path=${busSocket}' || true; pkill -f '^waypipe .*--display ${displaySocket}' || true; rm -f ${displaySocket} ${busSocket}"
                }

                exec waypipe ${lib.escapeShellArgs cfg.flags} --display ${displaySocket} \
                    ssh -R ${audioSocket}:"$XDG_RUNTIME_DIR/pulse/native" \
                        -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
                        ${lib.escapeShellArg host} waypipe-session-leader ${busSocket}
            '';
        };

    # Polls on the far side, so waiting for the bus costs one connection rather than one per attempt
    sessionReady =
        host:
        pkgs.writeShellApplication {
            name = "waypipe-session-${host}-ready";
            runtimeInputs = [ pkgs.openssh ];
            text = ''
                exec ssh -o BatchMode=yes ${lib.escapeShellArg host} ${
                    lib.escapeShellArg "for _ in $(seq 60); do if test -S ${busSocket}; then exit 0; fi; sleep 0.2; done; exit 1"
                }
            '';
        };

    # Start blocks until ExecStartPost returns, so the app never races the display it is about to connect to
    launcher =
        key: app:
        pkgs.writeShellApplication {
            name = "waypipe-${key}";
            runtimeInputs = with pkgs; [
                openssh
                systemd
            ];
            text = ''
                # A session parked in failed state by the start limit would otherwise refuse every later launch
                systemctl --user reset-failed ${unitName app.host}.service || true
                systemctl --user start ${unitName app.host}.service
                exec ssh -o BatchMode=yes ${lib.escapeShellArg app.host} ${lib.escapeShellArgs (remoteArgv app)}
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
            description = "Waypipe flags applied to each session, so tuning changes in one place.";
        };

        apps = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule appOptions);
            default = { };
            description = "Applications run on another host and displayed on this one.";
        };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
        # Sessions -----------------------------------------------------------------------------------------------------------------------------------
        {
            home-manager.users.beatlink.systemd.user.services = lib.listToAttrs (
                map (
                    host:
                    lib.nameValuePair (unitName host) {
                        Unit = {
                            Description = "Shared waypipe session on ${host}";
                            After = [ "graphical-session.target" ];
                            PartOf = [ "graphical-session.target" ];

                            # Without a limit the 5s restart never trips systemd's default, so an unreachable host would be retried forever
                            StartLimitBurst = 3;
                            StartLimitIntervalSec = 60;
                        };

                        # No Install section: a launcher starts this on demand, so a boot with the other host off does not retry forever
                        Service = {
                            ExecStart = lib.getExe (sessionRunner host);
                            ExecStartPost = lib.getExe (sessionReady host);
                            Restart = "on-failure";
                            RestartSec = 5;
                        };
                    }
                ) hosts
            );
        }

        # Launchers ----------------------------------------------------------------------------------------------------------------------------------
        {
            home-manager.users.beatlink.home.packages =
                [ pkgs.waypipe ]
                ++ lib.flatten (lib.mapAttrsToList (key: app: [ (launcher key app) (desktopItem key app) ]) cfg.apps);

            # In the system profile, because the far end resolves it on a non-login PATH that need not carry the user's own
            environment.systemPackages = [ sessionLeader ];
        }

        # Access -------------------------------------------------------------------------------------------------------------------------------------
        {
            sops.secrets.waypipe_key = {
                sopsFile = "${config.technet.secrets.path}/waypipe.yaml";
                owner = "beatlink";
            };

            users.users.beatlink.openssh.authorizedKeys.keys = [ (if isOdin then thorToOdin else odinToThor) ];

            # An audio forward leaves its socket file behind, and sshd refuses to bind over one, so the next launch would come up silent
            services.openssh.settings.StreamLocalBindUnlink = true;

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
