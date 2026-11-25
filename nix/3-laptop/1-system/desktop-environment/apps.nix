# Session Apps #######################################################################################################################################
#
# Runs long-lived desktop apps as user services started with the display, and points their menu entries at the service instead of the binary.
# A service app behaves like any other app: it is not restarted when it exits or crashes, and its launcher starts it again.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.desktop.apps;

    # Starts the app's service if it is down, then hands the launch to the running copy.
    launcher =
        name: app:
        pkgs.writeShellScript "${name}-launch" ''
            unit=${lib.escapeShellArg "${name}.service"}
            if ! ${pkgs.systemd}/bin/systemctl --user is-active --quiet "$unit"; then
                ${pkgs.systemd}/bin/systemctl --user start "$unit" || exit 1
                ${
                    if app.socket == null then
                        "exit 0"
                    else
                        ''
                            ready=1
                            for _ in $(${pkgs.coreutils}/bin/seq 50); do
                                if ${pkgs.socat}/bin/socat -u /dev/null UNIX-CONNECT:"${app.socket}" 2>/dev/null; then
                                    ready=0
                                    break
                                fi
                                ${pkgs.coreutils}/bin/sleep 0.2
                            done
                            [ "$ready" = 0 ] || exit 1
                        ''
                }
            fi
            exec ${lib.escapeShellArg app.command} "$@"
        '';

    # Copies the package's desktop entry with every Exec of the app's binary pointed at its launcher.
    desktopEntry =
        name: app:
        pkgs.runCommand "${name}-desktop-entry" { } ''
            ${pkgs.gawk}/bin/awk -v bin=${lib.escapeShellArg (baseNameOf app.command)} -v launcher=${launcher name app} '
                /^Exec=/ {
                    n = split(substr($1, 6), parts, "/")
                    if (parts[n] == bin) $1 = "Exec=" launcher
                }
                { print }
            ' ${lib.escapeShellArg app.desktopFile} > $out
            ${pkgs.gnugrep}/bin/grep -q '^Exec=${launcher name app}' $out || {
                echo "no Exec in ${app.desktopFile} runs ${baseNameOf app.command}" >&2
                exit 1
            }
        '';
in
{
    options.technet.desktop.apps = lib.mkOption {
        default = { };
        description = "Desktop apps run as user services, keyed by unit name.";
        type = lib.types.attrsOf (
            lib.types.submodule {
                options = {
                    description = lib.mkOption {
                        type = lib.types.str;
                        description = "The unit's description.";
                    };
                    command = lib.mkOption {
                        type = lib.types.str;
                        description = "Absolute path of the app's binary, which the service runs and the launcher hands off to.";
                    };
                    args = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = [ ];
                        description = "Arguments only the service passes, such as starting hidden.";
                    };
                    desktopFile = lib.mkOption {
                        type = lib.types.nullOr lib.types.path;
                        default = null;
                        description = "The package's desktop entry, shadowed by a copy that launches through the service.";
                    };
                    socket = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Socket the running copy takes hand-offs on, expanded by the shell; without one a launch that starts the service drops its arguments.";
                    };
                };
            }
        );
    };

    config.home-manager.users.beatlink = {
        systemd.user.services = lib.mapAttrs (name: app: {
            Unit = {
                Description = app.description;
                PartOf = [ "graphical-session.target" ];
                Requires = [ "display.target" ];
                After = [ "display.target" ];
            };
            Service.ExecStart = lib.escapeShellArgs ([ app.command ] ++ app.args);
            Install.WantedBy = [ "display.target" ];
        }) cfg;

        xdg.dataFile = lib.mapAttrs' (
            name: app:
            lib.nameValuePair "applications/${builtins.unsafeDiscardStringContext (baseNameOf app.desktopFile)}"
                { source = desktopEntry name app; }
        ) (lib.filterAttrs (_: app: app.desktopFile != null) cfg);
    };
}
