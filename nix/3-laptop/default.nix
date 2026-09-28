# Module Imports
#

{
    technet.secrets.directory = "3-laptop";
    technet.codecs.enable = true;
    technet.activitywatch = {
        monitor = true;
        sessionTarget = "display.target"; # Cinnamon hands the user manager its display only after graphical-session.target
    };

    imports = [
        ./1-system
        ./4-apps
    ];
}
