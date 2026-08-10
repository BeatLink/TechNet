# Home Assistant #####################################################################################################################################
#
# The dashboard as its own window, through WebLaunch, which is the only accelerated web client on Thor's Mali-400.
#

{ inputs, ... }:
{
    imports = [ inputs.weblaunch.nixosModules.default ];

    programs.weblaunch = {
        enable = true;

        apps.home-assistant = {
            name = "Home Assistant";
            url = "https://home-assistant.heimdall.technet";
            icon = ./home-assistant.png;

            profile = "/home/beatlink/.local/share/weblaunch/HomeAssistant"; # Explicit so impermanence has a stable path to persist the login under
        };
    };

    home-manager.users.beatlink.home.persistence."/Storage/Apps/TechNet/HomeAssistant" = {
        directories = [ ".local/share/weblaunch/HomeAssistant" ];
    };
}
