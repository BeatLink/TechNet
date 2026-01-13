{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ tilix ];
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                persistence."/Storage/Apps/Tools/Tilix" = {
                    directories = [
                    ];

                };
            };
            imports = [
                ./2-dconf-settings.nix
            ];
            xdg.desktopEntries."com.gexperts.Tilix" = {
                name = "Tilix";
                genericName = "Terminal emulator";
                comment = "A tiling terminal for GNOME";
                exec = "${pkgs.tilix}/bin/tilix";
                terminal = false;
                type = "Application";
                startupNotify = true;
                icon = "com.gexperts.Tilix";
                categories = [
                    "System"
                    "TerminalEmulator"
                    "X-GNOME-Utilities"
                ];
                settings = {
                    Keywords = "shell;prompt;command;commandline;cmd;terminal;";
                    StartupWMClass = "Tilix";
                    # DBusActivatable intentionally removed
                };
                actions = {
                    "new-window" = {
                        name = "New Window";
                        exec = "${pkgs.tilix}/bin/tilix --action=app-new-window";
                    };
                    "new-session" = {
                        name = "New Session";
                        exec = "${pkgs.tilix}/bin/tilix --action=app-new-session";
                    };
                    "preferences" = {
                        name = "Preferences";
                        exec = "${pkgs.tilix}/bin/tilix --preferences";
                    };
                };
            };
        };
}
