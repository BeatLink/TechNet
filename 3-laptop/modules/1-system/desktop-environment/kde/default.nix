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
    };
    environment.plasma6.excludePackages = with pkgs.kdePackages; [      # Exclude Default Packages
        elisa
        discover
        kate
    ];
    imports = [                                                         # Import Other Modules
        ./hot-corners.nix
        ./panels.nix
        ./power.nix
        ./screenlock.nix
        ./workspace.nix
    ];

    # services.flatpak.packages = [ "flathub:runtime/org.gtk.Gtk3theme.Breeze//stable" ];
    #org.gtk.Gtk3theme.Breeze
}