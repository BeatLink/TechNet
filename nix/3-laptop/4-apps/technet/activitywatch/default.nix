# ActivityWatch ######################################################################################################################################
#
# A launcher for Heimdall's ActivityWatch web UI, which shows every monitored host rather than this one alone.
#
{
    home-manager.users.beatlink = {
        home.file = {
            ".local/share/icons/activitywatch.png".source = ./activitywatch.png;

            ".local/share/applications/activitywatch.desktop".text = ''
                [Desktop Entry]
                Name=ActivityWatch
                Exec=firefox https://activitywatch.heimdall.technet
                Comment=Time tracking across Odin and Thor
                Terminal=false
                PrefersNonDefaultGPU=false
                Icon=activitywatch.png
                Categories=Utility
                Type=Application
            '';
        };
    };
}
