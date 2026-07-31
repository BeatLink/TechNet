# Wallpaper
#
# hyprpaper handles the desktop wallpaper, with Variety (configured in 4-apps/system/variety.nix) choosing
# which image to show.
#
# Variety does not write a stable filename. Each time it changes wallpaper it copies the image to a new
# hash-suffixed name and points the desktop at it — under Cinnamon by setting
# org.cinnamon.desktop.background picture-uri. Pointing hyprpaper at a fixed path therefore never worked:
# the file simply did not exist, and hyprpaper logged "Monitor eDP-1 has no target: no wp will be created".
#
# Instead a small service reads the path Variety recorded and hands it to hyprpaper over IPC. It runs at
# login and whenever Variety updates the file, so the wallpaper follows Variety's rotation.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        let
            # Variety records the source image of the current wallpaper alongside its copy of it.
            currentFile = "${config.home.homeDirectory}/.config/variety/wallpaper/wallpaper.jpg.txt";

            applyWallpaper = pkgs.writeShellScript "hyprpaper-apply-variety" ''
                set -u
                current="${currentFile}"
                [ -r "$current" ] || exit 0

                target=$(${pkgs.coreutils}/bin/head -c 4096 "$current" | ${pkgs.coreutils}/bin/tr -d '\n')
                [ -n "$target" ] && [ -r "$target" ] || exit 0

                # `unload` is rejected by this hyprpaper build, so images stay preloaded for the life of the
                # process. Variety rotates infrequently enough for that not to matter.
                ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$target" >/dev/null 2>&1 || true
                ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$target" >/dev/null 2>&1 || exit 1
            '';
        in
        {
            services.hyprpaper = {
                enable = true;
                settings = {
                    ipc = "on"; # Required: the apply script drives hyprpaper over IPC
                    splash = false;
                };
            };

            systemd.user = {
                services.hyprpaper-variety = {
                    Unit = {
                        Description = "Apply the wallpaper Variety selected to hyprpaper";
                        After = [ "hyprpaper.service" ];
                        PartOf = [ "graphical-session.target" ];
                    };
                    Service = {
                        Type = "oneshot";
                        ExecStart = "${applyWallpaper}";
                    };
                    Install.WantedBy = [ "graphical-session.target" ];
                };

                # Re-apply when Variety records a new wallpaper.
                paths.hyprpaper-variety = {
                    Unit = {
                        Description = "Watch for wallpaper changes from Variety";
                        PartOf = [ "graphical-session.target" ];
                    };
                    Path.PathChanged = currentFile;
                    Install.WantedBy = [ "graphical-session.target" ];
                };
            };
        };
}
