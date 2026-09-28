# ActivityWatch ######################################################################################################################################
#
# Records the active window and idle time on this host into a local aw-server, and exports it for Heimdall's ActivityWatch to import.
# aw-sync pushes pulled buckets back out as well, so a monitor only pushes and Heimdall only pulls, or every host's data multiplies.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.activitywatch;

    awServer = pkgs.aw-server-rust;
    syncDir = "/Storage/Files/ActivityWatch"; # The Syncthing folder of that name, shared with every mesh peer
    serverPort = 5600;
    pushInterval = "5m";

    # awatcher logs an error every second the screen is locked, and LogFilterPatterns has no effect in the user manager
    awatcher = pkgs.writeShellScript "awatcher" ''
        set -o pipefail
        ${lib.getExe pkgs.awatcher} --port ${toString serverPort} -vv 2>&1 |
            ${pkgs.gnugrep}/bin/grep --line-buffered -v "Current window is unknown"
    '';

    # A monitor on rsync exports into a folder of its own and copies that to Heimdall, since it is not a Syncthing peer
    monitorSyncDir = "%h/.local/share/activitywatch/sync";
in
{
    options.technet.activitywatch = {
        monitor = lib.mkEnableOption "recording this host's window and idle activity for ActivityWatch";

        transport = lib.mkOption {
            type = lib.types.enum [
                "syncthing"
                "rsync"
            ];
            default = "syncthing";
            description = "How this monitor's export reaches Heimdall: the shared Syncthing folder, or rsync over SSH for a host outside the mesh.";
        };

        sessionTarget = lib.mkOption {
            type = lib.types.str;
            default = "graphical-session.target";
            description = "User target at which the session's display is reachable, which the window watcher starts from.";
        };
    };

    config = lib.mkMerge [
        # Monitor ------------------------------------------------------------------------------------------------------------------------------------
        (lib.mkIf cfg.monitor {
            home-manager.users.beatlink = {
                home.persistence."/Storage/Apps/TechNet/ActivityWatch".directories = [
                    ".local/share/activitywatch"
                ];

                systemd.user.services.aw-server = {
                    Unit.Description = "ActivityWatch server";
                    Service = {
                        ExecStart = "${lib.getExe awServer} --host 127.0.0.1 --port ${toString serverPort}";
                        Restart = "on-failure";
                        RestartSec = 10;
                    };
                    Install.WantedBy = [ "default.target" ];
                };

                systemd.user.services.awatcher = {
                    Unit = {
                        Description = "ActivityWatch window and idle watcher";
                        PartOf = [ "graphical-session.target" ];
                        Requires = [ cfg.sessionTarget ];
                        Wants = [ "aw-server.service" ];
                        After = [
                            cfg.sessionTarget
                            "aw-server.service"
                        ];
                    };
                    Service = {
                        ExecStart = awatcher;
                        Restart = "on-failure";
                        RestartSec = 10;
                    };
                    Install.WantedBy = [ cfg.sessionTarget ];
                };

                systemd.user.services.aw-sync = {
                    Unit = {
                        Description = "Export this host's ActivityWatch history for Heimdall";
                        Requires = [ "aw-server.service" ];
                        After = [ "aw-server.service" ];
                    };
                    Service = {
                        Type = "oneshot";
                        # No mkdir for the Syncthing folder: a directory that exists before Syncthing adds it has no marker, and the folder never starts
                        ExecStart =
                            if cfg.transport == "syncthing" then
                                "${awServer}/bin/aw-sync --port ${toString serverPort} --sync-dir ${syncDir} sync-advanced --mode push"
                            else
                                [
                                    "${pkgs.coreutils}/bin/mkdir -p ${monitorSyncDir}"
                                    "${awServer}/bin/aw-sync --port ${toString serverPort} --sync-dir ${monitorSyncDir} sync-advanced --mode push"
                                    "${pkgs.rsync}/bin/rsync -rt -e ${pkgs.openssh}/bin/ssh ${monitorSyncDir}/ heimdall-activitywatch:"
                                ];
                    };
                };

                systemd.user.timers.aw-sync = {
                    Unit.Description = "Export this host's ActivityWatch history every few minutes";
                    Timer = {
                        OnStartupSec = "5m";
                        OnUnitActiveSec = pushInterval;
                    };
                    Install.WantedBy = [ "timers.target" ];
                };
            };
        })

        # Reaching Heimdall over SSH -----------------------------------------------------------------------------------------------------------------
        (lib.mkIf (cfg.monitor && cfg.transport == "rsync") {
            sops.secrets.activitywatch_sync_key = {
                sopsFile = "${config.technet.secrets.path}/activitywatch.yaml";
                owner = "beatlink";
            };

            programs.ssh.extraConfig = ''

                Host heimdall-activitywatch
                    HostName heimdall.technet
                    User beatlink
                    IdentityFile ${config.sops.secrets.activitywatch_sync_key.path}
                    IdentitiesOnly yes
            '';
        })
    ];
}
