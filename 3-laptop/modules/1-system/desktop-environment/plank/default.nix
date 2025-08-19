# Plank Dock
# 
# This dock is used for quickly launching applications.
#
# Launchers are grouped into categories seperated via separators.
#

# Apps
# 
#   firefox
#   keepassxc
#   trilium
#   nemo
#
#   thunderbird
#   whatsapp
#   whatsapp-private
#   discord
#   element
#
#   newsflash
#   gmusicbrowser
#   freetube
#   stremio
#   lutris
#   steam
#   calibre
#   LMMS
#   timestretcher
#   pix
#   
#   home-assistant
#   nextcloud
#   
#   tilix
#   vscodium
#   virt-manager



{
    services.bamf.enable = true;                                             # Allows plank to know running applications
    home-manager.users.beatlink = { pkgs, plank-reloaded, ... }: {
        home = {
            packages = [ plank-reloaded.packages.${pkgs.system}.plank-reloaded ];
            persistence = {
                "/Storage/Apps/System/Plank" = {                                # Loads persistent data for plank
                    directories = [
                        ".local/share/plank"
                        ".cache/plank"
                        ".config/plank"
                    ];
                    allowOther = true;
                };
            };
        };
        dconfImports.plank = {
            source = ./settings.dconf;
            path = "/net/launchpad/plank/";
        };
    };

}

/*
{pkgs, ...}: {
            settings = {
                "net/launchpad/plank/docks/dock1" = {
                    alignment = "center";
                    auto-pinning = true;
                    current-workspace-only = false;
                    dock-items = dockitemDconfNames;
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
    };
}
*/