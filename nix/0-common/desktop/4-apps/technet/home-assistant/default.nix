# Home Assistant, as its own window on both hosts.
#
# This is the third client to hold this slot. The `firefox --kiosk` desktop
# entry was a shell command with an icon; Butler was a GTK4/libadwaita wrapper
# and inherited GTK4's inability to obtain a GL context on Thor's Mali-400.
# WebLaunch is GTK3 against webkit2gtk-4.1 and asks for GLES 2.0, which is the
# one request lima grants -- 0.39 cores against 1.52 on an animating page.
#
# Shared rather than per-host because the reasoning holds on both, for different
# reasons: on Thor it is the only accelerated path, and on Odin it is simply a
# dedicated window with its own session instead of a tab that gets lost.
#
# What it does not fix, and this is worth stating where the launcher lives: the
# dashboard costs a full CPU core and 90% of Thor's GPU while sitting untouched,
# because its frontend re-renders as state arrives. That is main-thread
# JavaScript, which no engine parallelises -- the remaining lever is a simpler
# dashboard, not a faster client.
{ inputs, ... }:
{
    imports = [ inputs.weblaunch.nixosModules.default ];

    programs.weblaunch = {
        enable = true;

        apps.home-assistant = {
            name = "Home Assistant";
            url = "https://home-assistant.heimdall.technet";
            icon = ./home-assistant.png;

            # Explicit so it is the same path on both hosts, and so Thor's
            # impermanence has something stable to persist -- a login that has
            # to be redone on every boot is worse than no launcher.
            profile = "/home/beatlink/.local/share/weblaunch/HomeAssistant";
        };
    };

    home-manager.users.beatlink.home.persistence."/Storage/Apps/TechNet/HomeAssistant" = {
        directories = [ ".local/share/weblaunch/HomeAssistant" ];
    };
}
