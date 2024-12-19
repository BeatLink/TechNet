{ config, lib, pkgs, ... }:
{
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
                "org.kde.plasma.systemtray"
            ];
        }
        {
            location = "bottom";
            height = 32;
            lengthMode = "fit";
            hiding = "dodgewindows";
            floating = true;
            widgets = [
                "org.kde.plasma.pager"
                "org.kde.plasma.icontasks"
            ];
        }
    ];
}