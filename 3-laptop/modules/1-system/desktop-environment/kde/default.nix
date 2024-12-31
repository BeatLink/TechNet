{ config, lib, pkgs, ... }:
{
    services =  {
        displayManager.sddm =  {                                        # Enable SDDM Login Manager
            enable = true;
            wayland.enable = true;
        };
        desktopManager.plasma6.enable = true;                           # Enable KDE Desktop Environment
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {              # Enable Plasma Manager
        programs.plasma.enable = true;
        home = {
            persistence."/Storage/Apps/System/KDE" = {
                directories = [ ];
                files = [
                    ".config/kwinoutputconfig.json"
                ];
                allowOther = true;
            };
        };
    };
    environment.plasma6.excludePackages = with pkgs.kdePackages; [      # Exclude Default Packages
        elisa
        discover
        kate
    ];
    imports = [                                                         # Import Other Modules
        ./dolphin.nix
        ./hot-corners.nix
        ./kde-connect.nix
        ./kwallet.nix
        ./panels.nix
        ./power.nix
        ./screenlock.nix
        ./workspace.nix
        
    ];

    # services.flatpak.packages = [ "flathub:runtime/org.gtk.Gtk3theme.Breeze//stable" ];
    #org.gtk.Gtk3theme.Breeze
}