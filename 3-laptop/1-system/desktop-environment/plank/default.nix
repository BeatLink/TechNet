# Plank Dock
# 
# This dock is used for quickly launching applications.
#
# Launchers are grouped into categories seperated via separators.
#
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
#   steam
#   lutris
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
    home-manager.users.beatlink = { pkgs, inputs, ... }: 
    let 
        plank-reloaded = inputs.plank-reloaded.defaultPackage.${pkgs.system};
    in {
        home = {
            packages = [ plank-reloaded ];
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
        systemd.user.services.plank = {
            Unit = {
                Description = "Start Plank Dock on graphical login";
                After = [ "dconf.service" "graphical-session.target" ];
                Wants = [ "dconf.service" "graphical-session.target" ];
            };
            Service = {
                ExecStart = "${plank-reloaded}/bin/plank";
                Type = "simple";
                Restart = "always";
            };
            Install = {
                WantedBy = [ "default.target" ];
            };
        };
    };
}
