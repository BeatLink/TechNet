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
        };
    };
}