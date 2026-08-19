# Phone Apps #########################################################################################################################################
#
# The state of the applications Thor runs here over waypipe. It lives under /Storage/PhoneApps rather than in this user's home, because it
# belongs to the phone's sessions rather than to Odin's; the launchers that name these paths are declared on Thor, under 5-phone/3-apps.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    # Declares each path as a directory belonging to beatlink.
    dirs =
        paths:
        lib.genAttrs paths (_: {
            d = {
                user = "beatlink";
                group = "beatlink";
                mode = "0755";
            };
        });
in
{
    config = lib.mkMerge [
        # Storage Root -------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [ "/Storage/PhoneApps" ];
        }

        # Firefox ------------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Firefox"
                "/Storage/PhoneApps/Firefox/Thor"
            ];
        }

        # KeePassXC ----------------------------------------------------------------------------------------------------------------------------------
        (
            let
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
                systemd.tmpfiles.settings.PhoneApps = dirs [
                    "/Storage/PhoneApps/KeePassXC"
                    "/Storage/PhoneApps/KeePassXC/Thor"
                ]
                // {
                    # Copied rather than linked, because KeePassXC rewrites its config on startup and would replace a store symlink with a file
                    "/Storage/PhoneApps/KeePassXC/Thor/keepassxc.ini".C = {
                        argument = "${thorConfig}";
                        user = "beatlink";
                        group = "beatlink";
                        mode = "0644";
                    };
                };
            }
        )

        # Trilium ------------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Trilium"
                "/Storage/PhoneApps/Trilium/Thor"
            ];
        }

        # FreeTube -----------------------------------------------------------------------------------------------------------------------------------
        (
            let
                # Safe because FreeTube resolves each database's realpath before opening it, so nedb compacting over the target leaves the link alone
                shareWithThor =
                    name:
                    lib.nameValuePair "/Storage/PhoneApps/FreeTube/Thor/${name}.db" {
                        "L+".argument = "/home/beatlink/.config/FreeTube/${name}.db";
                    };
            in
            {
                systemd.tmpfiles.settings.PhoneApps = dirs [
                    "/Storage/PhoneApps/FreeTube"
                    "/Storage/PhoneApps/FreeTube/Thor"
                ]
                # settings.db is left out so the phone keeps its own UI scale, and subscription-cache.db because sharing the busiest file buys nothing
                // lib.listToAttrs (
                    map shareWithThor [
                        "profiles" # Subscriptions live in here, as an array on each profile rather than a database of their own
                        "playlists"
                        "history"
                    ]
                );
            }
        )

        # VSCodium -----------------------------------------------------------------------------------------------------------------------------------
        (
            let
                # The same settings as Odin's instance, plus the in-window file picker, because a portal dialog is drawn by Odin's session and lands on Odin's screen
                thorSettings = (pkgs.formats.json { }).generate "vscode-user-settings-thor" (
                    config.home-manager.users.beatlink.programs.vscodium.profiles.default.userSettings
                    // {
                        "files.simpleDialog.enable" = true;
                    }
                );
            in
            {
                systemd.tmpfiles.settings.PhoneApps = dirs [
                    "/Storage/PhoneApps/VSCodium"
                    "/Storage/PhoneApps/VSCodium/Thor"
                    "/Storage/PhoneApps/VSCodium/Thor/User"
                ]
                // {
                    "/Storage/PhoneApps/VSCodium/Thor/User/settings.json"."L+".argument = "${thorSettings}";
                };
            }
        )

        # Thunderbird --------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Thunderbird"
                "/Storage/PhoneApps/Thunderbird/Thor"
            ];
        }

        # Element ------------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Element"
                "/Storage/PhoneApps/Element/Thor"
            ];
        }

        # Discord ------------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Discord"
                "/Storage/PhoneApps/Discord/Thor"
            ];
        }

        # Quod Libet ---------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/QuodLibet"
                "/Storage/PhoneApps/QuodLibet/Thor"
            ];
        }

        # LibreOffice --------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/LibreOffice"
                "/Storage/PhoneApps/LibreOffice/Thor"
            ];
        }
    ];
}
