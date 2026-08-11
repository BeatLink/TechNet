# Phone Apps #########################################################################################################################################
#
# What Thor's waypipe launchers cost on this side: a second config or data root per app, beside Odin's own rather than inside it, so both
# instances run at once. The launchers themselves are declared on Thor, under 5-phone/3-apps.
#
{ lib, ... }:
{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            config = lib.mkMerge [
                # Firefox ----------------------------------------------------------------------------------------------------------------------------
                {
                    # Outside the profile root, so profiles.ini never lists it and Sync does not refuse the second copy
                    home.persistence."/Storage/Apps/Core/Firefox".directories = [
                        ".config/mozilla/firefox-waypipe"
                    ];
                }

                # KeePassXC --------------------------------------------------------------------------------------------------------------------------
                (
                    let
                        thorConfigDir = "${config.xdg.configHome}/keepassxc-waypipe/Thor";

                        # Thor has no system tray, so anything that parks the window in one leaves that instance with no window at all
                        thorConfig = (pkgs.formats.ini { }).generate "keepassxc-thor.ini" {
                            General = {
                                SingleInstance = false; # Otherwise the launch is handed to the instance running here and opens on this screen
                                MinimizeAfterUnlock = false;
                                HideWindowOnCopy = false;
                                DropToBackgroundOnCopy = false;
                            };

                            GUI = {
                                MinimizeOnStartup = false;
                                MinimizeOnClose = false;
                                MinimizeToTray = false;
                                ShowTrayIcon = false;
                            };

                            SSHAgent.Enabled = false; # The instance autostarted here already adds the database's keys to gcr-ssh-agent
                            Browser.Enabled = false; # One proxy socket per user, so a second server would take it from the first
                        };
                    in
                    {
                        # Seeded rather than linked, because KeePassXC rewrites its config on startup and would replace a store symlink with a file
                        home.activation.keepassxcThorConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
                            if [ ! -e ${thorConfigDir}/keepassxc.ini ]; then
                                run mkdir -p ${thorConfigDir}
                                run install -m 644 ${thorConfig} ${thorConfigDir}/keepassxc.ini
                            fi
                        '';

                        home.persistence."/Storage/Apps/Core/KeePassXC".directories = [
                            ".config/keepassxc-waypipe"
                        ];
                    }
                )

                # Trilium ----------------------------------------------------------------------------------------------------------------------------
                {
                    home.persistence."/Storage/Apps/Core/Trilium".directories = [
                        ".config/trilium-waypipe"
                        ".local/share/trilium-waypipe"
                    ];
                }

                # FreeTube ---------------------------------------------------------------------------------------------------------------------------
                (
                    let
                        # Links one of Odin's databases into Thor's user data dir, so the two instances share it.
                        shareWithThor =
                            name:
                            lib.nameValuePair ".config/freetube-waypipe/Thor/${name}.db" {
                                source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/FreeTube/${name}.db";
                            };
                    in
                    {
                        # settings.db is left out so the phone keeps its own UI scale, and subscription-cache.db because sharing the busiest file buys nothing
                        home.file = lib.listToAttrs (
                            map shareWithThor [
                                "profiles" # Subscriptions live in here, as an array on each profile rather than a database of their own
                                "playlists"
                                "history"
                            ]
                        );

                        home.persistence."/Storage/Apps/Fun/FreeTube".directories = [
                            ".config/freetube-waypipe"
                        ];
                    }
                )

                # VSCodium ---------------------------------------------------------------------------------------------------------------------------
                {
                    # The same settings as Odin's instance, plus the in-window file picker, because a portal dialog is drawn by Odin's session and lands on Odin's screen
                    home.file."${config.xdg.configHome}/vscodium-waypipe/Thor/User/settings.json".source =
                        (pkgs.formats.json { }).generate "vscode-user-settings-thor" (
                            config.programs.vscodium.profiles.default.userSettings
                            // {
                                "files.simpleDialog.enable" = true;
                            }
                        );

                    home.persistence."/Storage/Apps/Programming/VsCodium".directories = [
                        ".config/vscodium-waypipe"
                    ];
                }
            ];
        };
}
