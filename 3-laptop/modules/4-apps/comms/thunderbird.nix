{ config, pkgs, ... }: 
{
    services.flatpak.packages = [
        "flathub:app/org.mozilla.Thunderbird//stable"
        "flathub:app/com.ulduzsoft.Birdtray//stable"
    ];
    programs.fuse.userAllowOther = true;
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Comms/Thunderbird" = {
                directories = [
                    ".var/app/org.mozilla.Thunderbird"
                    ".var/app/com.ulduzsoft.Birdtray"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/com.ulduzsoft.Birdtray.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/app/com.ulduzsoft.Birdtray/current/active/files/share/applications/com.ulduzsoft.Birdtray";
                ".config/plank/dock1/launchers/org.mozilla.Thunderbird.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/org.mozilla.Thunderbird.desktop
                '';

            };
        };
    };
}