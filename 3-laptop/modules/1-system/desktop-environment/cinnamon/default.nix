# Cinnamon Settings #######################################################################################################################
#
# This module configures all the settings for the Cinnamon Desktop Environment. Cinnamon settings are stored in dconf-settings.nix. 
# It is automatically generated by export-dconf-settings.sh so you can change the cinnamon settings then export the changes without editing
# the file manually. 
#
###########################################################################################################################################

{ pkgs, ... }:
{  

    services = {
        displayManager.logToFile = false;
        displayManager.logToJournal = false;
        xserver = {
            enable = true;                                                          # Enables X11 Server
            displayManager.lightdm.enable = true;                                   # Enables LightDM Login Manager
            desktopManager.cinnamon.enable = true;                                  # Enables Cinnamon
            enableCtrlAltBackspace = true;                                          # Enables CTRL+ALT+Backspace for restarting X11
        };
        libinput.enable = true;                                                     # Enables Touchpad Functionality
        flatpak.packages = [                                                        # Installs flatpak GTK theme for Cinnamon
            "flathub:runtime/org.gtk.Gtk3theme.Mint-Y//3.22"
        ];
    };
    programs.dconf.enable = true;                                                   # Enable Dconf
    environment.cinnamon.excludePackages = with pkgs; [
        onboard
        gnome-calendar
        warpinator
        xterm
    ];
    home-manager.users.beatlink = {
        dconf.enable = true;                                                        # Enables dconf for Cinnamon setting Management
        imports = [                                                                 # Imports Cinnamon Dconf Settings
            ./2-dconf-settings.nix
            ./default-applications.nix
            ./fonts.nix
            ./night-light.nix
            ./themes.nix
        ];
        xsession =  {
            scriptPath = ".local/share/X11/xsession";
            initExtra =  "ERRFILE=$HOME/.local/share/X11/xsession-errors";
        };
        home.persistence."/Storage/Apps/System/Cinnamon" = {                                # Loads persistent data for plank
            directories = [
                ".config/cinnamon"
                ".config/cinnamon-session"
                ".local/share/cinnamon"
            ];
            allowOther = true;
        };
    };
 }

