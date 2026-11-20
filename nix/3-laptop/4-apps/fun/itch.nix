# itch ###############################################################################################################################################
#
# The itch.io launcher. Games install under ~/.config/itch/apps, and its preferences and install path are set from here at every activation.
#

{
    home-manager.users.beatlink =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            install_folder = "${config.home.homeDirectory}/.config/itch/apps";
            preferences = pkgs.writeText "itch-preferences.json" (
                builtins.toJSON {
                    defaultInstallLocation = "appdata";
                    downloadSelfUpdates = true;
                    offlineMode = false;
                    isolateApps = true;
                    closeToTray = true;
                    readyNotification = true;
                    showAdvanced = false;
                    openAtLogin = false;
                    openAsHidden = false;
                    manualGameUpdates = true;
                    preventDisplaySleep = true;
                    preferOptimizedPatches = false;
                    disableBrowser = false;
                    disableHardwareAcceleration = false;
                    enableTabs = true;
                }
            );
        in
        {
            home = {
                packages = [
                    (pkgs.symlinkJoin {
                        name = "itch";
                        paths = [ pkgs.itch ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        # Its wrapper reads no NIXOS_OZONE_WL, so the flags that switch it off X11 are spelled out here
                        postBuild = ''
                            wrapProgram $out/bin/itch --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true"
                        '';
                    })
                ];
                persistence."/Storage/Apps/Fun/Itch" = {
                    directories = [
                        ".config/itch"
                        ".renpy"
                    ];
                };

                # itch rewrites its preferences file and keeps the install path in its database, so both are merged into rather than linked read-only.
                activation.itchSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    preferences_file="$HOME/.config/itch/preferences.json"
                    if [ -e "$preferences_file" ]; then
                        merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$preferences_file" ${preferences})
                        run ${pkgs.coreutils}/bin/tee "$preferences_file" <<<"$merged" >/dev/null
                    else
                        run install -Dm644 ${preferences} "$preferences_file"
                    fi

                    database="$HOME/.config/itch/db/butler.db"
                    if [ -e "$database" ]; then
                        run ${pkgs.sqlite}/bin/sqlite3 -cmd '.timeout 5000' "$database" \
                            "UPDATE install_locations SET path = '${install_folder}' WHERE id = 'appdata'"
                    fi
                '';
            };
        };
}
