# Plank Dock ###############################################################################################################
# 
# This dock is used for quickly launching applications.
#
# Settings are stored via Dconf but are exported using the 1-export-dconf-settings.sh script in this folder
#
# Launchers are grouped into categories seperated via spaces. The spaces are generated by my plank separator script
# https://github.com/BeatLink/Plank-Separator
# X-GNOME-Autostart-Delay=0
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    environment.systemPackages = [ pkgs.plank ];                # Installs Plank from nixpkgs
    programs.fuse.userAllowOther = true;
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/System/Plank" = {
                directories = [
                    ".cache/plank"
                    ".config/plank"
                    ".local/share/plank"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/plank.desktop".source = "${pkgs.plank}/share/applications/plank.desktop";       # Configures plank to autostart on login
                
                ".config/plank/dock1/launchers/firefox.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/org.mozilla.firefox.desktop
                '';

                ".config/plank/dock1/launchers/org.keepassxc.KeePassXC.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/org.keepassxc.KeePassXC.desktop
                '';

                ".config/plank/dock1/launchers/org.mozilla.Thunderbird.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/org.mozilla.Thunderbird.desktop
                '';

                ".config/plank/dock1/launchers/im.riot.Riot.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/im.riot.Riot.desktop
                '';

                ".config/plank/dock1/launchers/com.vscodium.codium.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/com.vscodium.codium.desktop
                '';
            
            };
        };
        dconf.enable = true;                                    # Enables dconf which stores plank settings
        imports = [./2-dconf-settings.nix];                     # Imports the dconf settings

    };
}
