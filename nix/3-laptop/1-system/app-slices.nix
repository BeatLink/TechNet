# App Slices #########################################################################################################################################
#
# Gives the browser, the editor, each Claude Code session and the background apps a slice of their own, so a runaway is limited and killed alone.
#

{ pkgs, ... }:
let
    claude_scope = pkgs.writeShellScript "claude-scope" ''
        if [ -S "$XDG_RUNTIME_DIR/bus" ]; then
            exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet --collect --unit="app-claude-$$" -- "$@"
        fi
        exec "$@"
    '';

    scope_slices = {
        "app-firefox-" = "browser.slice";
        "app-codium-" = "editor.slice";
        "app-claude-" = "agents.slice";
    };

    background_units = [
        "syncthing.service"
        "syncthingtray.service"
        "codex-daemon.service"
        "codex-daemon-watch.service"
        "variety.service"
        "aw-server.service"
        "awatcher.service"
    ];
in
{
    technet.vscodium.userSettings."claudeCode.claudeProcessWrapper" = "${claude_scope}";

    home-manager.users.beatlink =
        { lib, ... }:
        {
            systemd.user.slices = {
                browser.Slice = {
                    MemoryHigh = "40%";
                    MemoryMax = "50%";
                };

                editor.Slice = {
                    MemoryHigh = "25%";
                    MemoryMax = "35%";
                };

                agents.Slice = {
                    MemoryHigh = "35%";
                    MemoryMax = "45%";
                    CPUWeight = 50;
                    IOWeight = 50;
                    ManagedOOMMemoryPressure = "kill";
                };

                background.Slice = {
                    CPUWeight = 20;
                    IOWeight = 20;
                };
            };

            # A scope's name is only known once the desktop or the wrapper creates it, so its slice comes from a drop-in matching the name's prefix.
            xdg.configFile = lib.mkMerge [
                (lib.mapAttrs' (
                    prefix: slice:
                    lib.nameValuePair "systemd/user/${prefix}.scope.d/slice.conf" {
                        text = ''
                            [Scope]
                            Slice=${slice}
                            # The default stops the whole app when the kernel kills one of its processes.
                            OOMPolicy=continue
                        '';
                    }
                ) scope_slices)

                # A session's builds and tools run inside its scope, so this cap is the whole session's.
                {
                    "systemd/user/app-claude-.scope.d/limits.conf".text = ''
                        [Scope]
                        MemoryHigh=6G
                        MemoryMax=8G
                    '';
                }

                (lib.listToAttrs (
                    map (
                        unit:
                        lib.nameValuePair "systemd/user/${unit}.d/slice.conf" {
                            text = ''
                                [Service]
                                Slice=background.slice
                            '';
                        }
                    ) background_units
                ))
            ];
        };
}
