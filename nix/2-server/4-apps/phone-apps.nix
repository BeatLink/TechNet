# Phone Apps #########################################################################################################################################
#
# The applications Thor displays over waypipe, and the state they keep. Nothing here draws on this host: each launch arrives as a non-login ssh
# session from the phone, and waypipe hands the process a Wayland display on the other end of it.
#
# The packages are system-wide rather than in beatlink's profile because that non-login session resolves argv on the system PATH alone, which is also
# why every launcher on Thor names a bare command.
#
# Most of the state lives under /Storage/PhoneApps, on the data pool rather than in a home the initrd rolls back, and belongs to the phone's sessions
# rather than to this host. The launchers that name these paths are declared on Thor, under 5-phone/3-apps/desktop. The few applications that offer no
# way to move their configuration keep it in beatlink's home instead, and are persisted here one by one.
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

    # Kept in beatlink's home because the application offers no way to move it, and so listed for the rollback to spare.
    persist = app: directories: {
        home-manager.users.beatlink.home.persistence."/Storage/Apps/PhoneApps/${app}".directories =
            directories;
    };
in
{
    config = lib.mkMerge [
        # Storage Root -------------------------------------------------------------------------------------------------------------------------------
        {
            systemd.tmpfiles.settings.PhoneApps = dirs [ "/Storage/PhoneApps" ];
        }

        # Firefox ------------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.firefox ]; # Also what the Home Assistant launcher opens, on a kiosk profile beside this one
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
                        SingleInstance = false; # Otherwise a second launch is handed to the copy still running in an earlier waypipe session, whose display is gone
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

                    SSHAgent.Enabled = false; # There is no agent on this host to add the database's keys to
                    Browser.Enabled = false; # One proxy socket per user, so a second server would take it from the first
                };
            in
            {
                environment.systemPackages = [ pkgs.keepassxc ];
                systemd.tmpfiles.settings.PhoneApps =
                    dirs [
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
            environment.systemPackages = [ pkgs.trilium-desktop ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Trilium"
                "/Storage/PhoneApps/Trilium/Thor"
            ];
        }

        # FreeTube -----------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.freetube ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/FreeTube"
                "/Storage/PhoneApps/FreeTube/Thor"
            ];
        }

        # VSCodium -----------------------------------------------------------------------------------------------------------------------------------
        (
            let
                # The same settings as Odin's instance, plus the in-window file picker, because there is no portal on this host to draw a dialog with
                thorSettings = (pkgs.formats.json { }).generate "vscode-user-settings-thor" (
                    config.technet.vscodium.userSettings
                    // {
                        "files.simpleDialog.enable" = true;
                    }
                );
            in
            {
                technet.vscodium.enable = true; # Extensions and this host's own settings, from the module Odin shares
                environment.systemPackages = [ pkgs.vscodium ];

                systemd.tmpfiles.settings.PhoneApps =
                    dirs [
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
            environment.systemPackages = [ pkgs.thunderbird ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Thunderbird"
                "/Storage/PhoneApps/Thunderbird/Thor"
            ];
        }

        # Element ------------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.element-desktop ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Element"
                "/Storage/PhoneApps/Element/Thor"
            ];
        }

        # Discord ------------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.discord ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/Discord"
                "/Storage/PhoneApps/Discord/Thor"
            ];
        }

        # Quod Libet ---------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [
                (pkgs.quodlibet.override {
                    withMusicBrainzNgs = true;
                    withDbusPython = true;
                })
            ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/QuodLibet"
                "/Storage/PhoneApps/QuodLibet/Thor"
            ];
        }

        # LibreOffice --------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.libreoffice ];
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/LibreOffice"
                "/Storage/PhoneApps/LibreOffice/Thor"
            ];
        }

        # gmusicbrowser ------------------------------------------------------------------------------------------------------------------------------
        {
            programs.gmusicbrowser.enable = true; # The flake's NixOS module, which is the one that installs system-wide
            systemd.tmpfiles.settings.PhoneApps = dirs [
                "/Storage/PhoneApps/GMusicBrowser"
                "/Storage/PhoneApps/GMusicBrowser/Thor"
            ];
        }

        # VLC ----------------------------------------------------------------------------------------------------------------------------------------
        {
            # Hardware decoding is forced off in the wrapper rather than in Thor's launcher, so a launch from anywhere gets a picture rather than green
            environment.systemPackages = [
                (pkgs.symlinkJoin {
                    name = "vlc";
                    paths = [ pkgs.vlc ];
                    nativeBuildInputs = [ pkgs.makeWrapper ];
                    postBuild = ''
                        wrapProgram $out/bin/vlc --add-flags "--avcodec-hw=none"
                    '';
                })
            ];
        }

        # NewsFlash ----------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.newsflash ];
        }
        (persist "NewsFlash" [
            ".cache/news_flash"
            ".config/news-flash"
            ".local/share/news_flash"
            ".local/share/news-flash"
        ])

        # Pix ----------------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.pix ];
        }
        (persist "Pix" [ ".config/pix" ])

        # XReader ------------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.xreader ];
        }
        (persist "XReader" [ ".config/xreader" ])

        # XViewer ------------------------------------------------------------------------------------------------------------------------------------
        {
            environment.systemPackages = [ pkgs.xviewer ];
        }
        (persist "XViewer" [ ".config/xviewer" ])
    ];
}
