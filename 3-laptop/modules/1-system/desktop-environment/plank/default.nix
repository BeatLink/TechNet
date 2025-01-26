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
let 

    plankItems = {
        "01-firefox" =  "file:///${pkgs.firefox}/share/applications/firefox.desktop";
        "02-keepassxc" = "file://${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop";
        "03-trilium" = "file://${pkgs.trilium-next-desktop}/share/applications/Trilium.desktop";
        "04-nemo" = "file:///run/booted-system/sw/share/applications/nemo.desktop";
        "05-separator1" = "file:///home/beatlink/.local/share/applications/separator1.desktop";
        "06-thunderbird" = "file:///var/lib/flatpak/exports/share/applications/org.mozilla.Thunderbird.desktop";
        "07-whatsapp" = "file:///home/beatlink/.local/share/applications/whatsapp.desktop";
        "08-whatsapp-private" = "file:///home/beatlink/.local/share/applications/whatsapp-private.desktop";
        "09-riot" = "file:///var/lib/flatpak/exports/share/applications/im.riot.Riot.desktop";
        "10-discord" = "file:///var/lib/flatpak/exports/share/applications/com.discordapp.Discord.desktop";
        "11-separator2" = "file:///home/beatlink/.local/share/applications/separator2.desktop";
        "12-newsflash" = "file:///${pkgs.newsflash}/share/applications/io.gitlab.news_flash.NewsFlash.desktop";
        "13-gmusicbrowser" = "file:///var/lib/flatpak/exports/share/applications/org.gmusicbrowser.gmusicbrowser.desktop";
        "14-freetube" = "file:///var/lib/flatpak/exports/share/applications/io.freetubeapp.FreeTube.desktop";
        "15-stremio" = "file:///var/lib/flatpak/exports/share/applications/com.stremio.Stremio.desktop";
        "16-steam" = "file:///run/booted-system/sw/share/applications/steam.desktop";
        "17-calibre" = "file:///var/lib/flatpak/exports/share/applications/com.calibre_ebook.calibre.desktop";
        "18-io.lmms.LMMS" = "file:///var/lib/flatpak/exports/share/applications/io.lmms.LMMS.desktop";
        "19-pix" = "file:///run/booted-system/sw/share/applications/pix.desktop";
        "20-separator3" = "file:///home/beatlink/.local/share/applications/separator3.desktop";
        "21-home-assistant" = "file:///home/beatlink/.local/share/applications/home-assistant.desktop";
        "22-nextcloud" = "file:///home/beatlink/.local/share/applications/nextcloud.desktop";
        "23-separator4" = "file:///home/beatlink/.local/share/applications/separator4.desktop";
        "24-terminal" = "file:///run/booted-system/sw/share/applications/org.gnome.Terminal.desktop";
        "25-vscodium" = "file:///var/lib/flatpak/exports/share/applications/com.vscodium.codium.desktop";
        "26-virt-manager" = "file:///run/booted-system/sw/share/applications/virt-manager.desktop";                   
        "27-separator5" = "file:///home/beatlink/.local/share/applications/separator5.desktop";
    };

    dockitemFiles = lib.attrsets.concatMapAttrs(name: value: {                  # Generates the dockitem files from the attrset above
        ".config/plank/dock1/launchers/${name}.dockitem".text = ''
            [PlankDockItemPreferences]
            Launcher=${value}
        '';
    }) plankItems;

in {
    services.bamf.enable = true;                                                # Allows plank to know running applications
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = [ pkgs.plank ];                                          # Installs Plank from nixpkgs
            persistence = {
                "/Storage/Apps/System/Plank" = {                                # Loads persistent data for plank
                    directories = [
                        ".local/share/plank"
                    ];
                    allowOther = true;
                };
                "/Storage/Apps/System/Separators/" = {                          # Loads custom separators used by panels
                    files = [
                        ".local/share/icons/separator-black-horizontal.png"
                        ".local/share/icons/separator-black-vertical.png"
                        ".local/share/icons/separator-blank.png"
                        ".local/share/icons/separator-white-horizontal.png"
                        ".local/share/icons/separator-white-vertical.png"
                        ".local/share/applications/separator1.desktop"
                        ".local/share/applications/separator2.desktop"
                        ".local/share/applications/separator3.desktop"
                        ".local/share/applications/separator4.desktop"
                        ".local/share/applications/separator5.desktop"
                    ];
                    allowOther = true;
                };
            };
            file = {
                ".config/autostart/plank.desktop".source = "${pkgs.plank}/share/applications/plank.desktop";       # Configures plank to autostart on login
            } // dockitemFiles;
        };
        dconf = {
            enable = true;                                                      # Enables dconf which stores plank settings
            settings = {
                "net/launchpad/plank/docks/dock1" = {
                    alignment = "center";
                    auto-pinning = true;
                    current-workspace-only = false;
                    dock-items = lib.attrsets.mapAttrsToList (name: value: name + ".dockitem") plankItems;
                    hide-delay = 200;
                    hide-mode = "dodge-active";
                    icon-size = 48;
                    items-alignment = "center";
                    lock-items = true;
                    monitor = "";
                    offset = 0;
                    pinned-only = false;
                    position = "bottom";
                    pressure-reveal = false;
                    show-dock-item = false;
                    theme = "Gtk+";
                    tooltips-enabled = true;
                    unhide-delay = 100;
                    zoom-enabled = true;
                    zoom-percent = 175;
                };
            };
        };
    };
}
