{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/System/Separators/" = {
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
                    "com.gitlab.scias.plasmavantage" #TODO: Enable once packaged for nix
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
                                "applications:Trilium.desktop"
                                "applications:org.kde.dolphin.desktop"
                                "file:///home/beatlink/.local/share/applications/separator1.desktop"
                                "applications:org.mozilla.Thunderbird.desktop"
                                "applications:whatsapp.desktop"
                                "applications:whatsapp-private.desktop"
                                "applications:im.riot.Riot.desktop"
                                "file:///home/beatlink/.local/share/applications/separator2.desktop"
                                # Newsflash
                                "applications:org.gmusicbrowser.gmusicbrowser.desktop"
                                "applications:io.freetubeapp.FreeTube.desktop"
                                "applications:com.stremio.Stremio.desktop"
                                "applications:com.valvesoftware.Steam.desktop"
                                "applications:calibre-gui.desktop"
                                "applications:io.lmms.LMMS.desktop"
                                "applications:org.kde.gwenview.desktop"
                                "file:///home/beatlink/.local/share/applications/separator3.desktop"
                                # Home Assistant
                                # Nextcloud
                                "file:///home/beatlink/.local/share/applications/separator4.desktop"
                                "applications:org.kde.konsole.desktop"
                                "applications:com.vscodium.codium.desktop"
                                "applications:virt-manager.desktop"
                            ];
                        };
                    }
                ];
            }
        ];
    };
}