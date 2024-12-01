{ config, pkgs, ... }: 
{
    home.file = {
        ".config/autostart/vorta.desktop".text = ''
            [Desktop Entry]
            Name=Vorta
            GenericName=Backup Software
            Exec=flatpak run com.borgbase.Vorta --daemonize
            Type=Application
            Icon=com.borgbase.Vorta
            Categories=Utility;Archiving;Qt;
            Keywords=borg;
            StartupWMClass=python3
            StartupNotify=false
            X-GNOME-Autostart-enabled=true
            X-GNOME-Autostart-Delay=20
        '';
    };
}