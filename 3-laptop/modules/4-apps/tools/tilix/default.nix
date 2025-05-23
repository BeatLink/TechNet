{pkgs, ...}:{
    services.xserver.excludePackages = [ pkgs.xterm ];
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ tilix ];
            persistence."/Storage/Apps/Tools/Tilix" = {
                directories = [
                ];
                allowOther = true;
            };
        };
        imports = [                                                                 # Imports Pix Dconf Settings
            ./2-dconf-settings.nix
        ];
        xdg.desktopEntries."com.gexperts.Tilix.desktop" = {
            name = "Tilix";
            genericName = "Terminal emulator";
            comment = "A tiling terminal for GNOME";
            exec = "tilix --focus-window --maximize"; # this is the main fix and the rest is to conform with original
            terminal = false;
            type = "Application";
            startupNotify = true;
            icon = "com.gexperts.Tilix";
            categories = [ "System" "TerminalEmulator" "X-GNOME-Utilities" ];
            settings = {
                Keywords = "shell;prompt;command;commandline;cmd;terminal;";
                DBusActivatable = "true";
            };
            actions = {
                "new-window" = {
                    name = "New Window";
                    exec = "tilix --action=app-new-window";
                };
                "new-session" = {
                    name = "New Session";
                    exec = "tilix --action=app-new-session";
                };

                "preferences" = {
                    name = "Preferences";
                    exec = "tilix --preferences";
                };

            };
        };
    };
}

