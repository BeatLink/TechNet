{ config, lib, pkgs, ... }:
{
    home.file = {
        ".local/share/plasma-manager/separator-blank.png".source = ./separator-blank.png;
        ".local/share/applications/separator1.desktop".text = ''
            [Desktop Entry]
            Name=Space
            Exec=true
            Terminal=false
            Hidden=true
            Type=Application
            Icon=/home/beatlink/.local/share/plasma-manager/separator-blank.png
        '';
        ".local/share/applications/separator2.desktop".text = ''
            [Desktop Entry]
            Name=Space
            Exec=true
            Terminal=false
            Hidden=true
            Type=Application
            Icon=/home/beatlink/.local/share/plasma-manager/separator-blank.png
        '';
        ".local/share/applications/separator3.desktop".text = ''
            [Desktop Entry]
            Name=Space
            Exec=true
            Terminal=false
            Hidden=true
            Type=Application
            Icon=/home/beatlink/.local/share/plasma-manager/separator-blank.png
        '';
    };
    programs.plasma.panels = [
        {
            location = "top";
            height = 32;
            lengthMode = "fill";
            hiding = "none";
            floating = true;
            widgets = [
                "org.kde.plasma.kickoff"
                "org.kde.plasma.panelspacer"
                {
                    digitalClock = {
                        calendar.firstDayOfWeek = "sunday";
                        date = {
                            format = "longDate";
                            position = "besideTime";
                        };
                        time.format = "12h";
                    };
                }
                "org.kde.plasma.panelspacer"
                "martchus.syncthingplasmoid"
                "org.kde.plasma.systemtray"
            ];
        }
        {
            location = "bottom";
            height = 48;
            lengthMode = "fit";
            hiding = "dodgewindows";
            floating = true;
            widgets = [
                "org.kde.plasma.pager"
                {
                    name = "org.kde.plasma.icontasks";
                    config = {
                        # /var/lib/flatpak/exports/share/applications/
                        # /run/booted-system/sw/share/applications/
                        General.launchers = [
                            "applications:org.mozilla.firefox.desktop"
                            "applications:org.keepassxc.KeePassXC.desktop"
                            # Trillium
                            # Money Manager
                            "applications:org.kde.dolphin.desktop"
                            "applications:separator1.desktop"
                            "applications:org.mozilla.Thunderbird.desktop"
                            "applications:whatsapp.desktop"
                            "applications:whatsapp-private.desktop"
                            "applications:im.riot.Riot.desktop"
                            "applications:com.discordapp.Discord.desktop"
                            "applications:separator2.desktop"
                            # Newsflash
                            "applications:org.gmusicbrowser.gmusicbrowser.desktop"
                            "applications:io.freetubeapp.FreeTube.desktop"
                            "applications:com.stremio.Stremio.desktop"
                            # Steam
                            # Calibre
                            # LMMS
                            "applications:org.kde.gwenview.desktop"
                            "applications:separator3.desktop"
                            # Home Assistant
                            # Nextcloud
                            "applications:org.kde.konsole.desktop"
                            "applications:com.vscodium.codium.desktop"
                            # Virt Manager
                        ];
                    };
                }
            ];
        }
    ];
}