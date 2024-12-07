{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = {
        home.file = {
            ".config/autostart/nvidia-prime.desktop".text = ''
                [Desktop Entry]
                Name=Support for NVIDIA Prime
                Comment=Shows a tray icon when a compatible NVIDIA Optimus graphics card is detected
                Exec=/usr/lib/nvidia-prime-applet/nvidia-prime
                Icon=prime-tray-nvidia
                Terminal=false
                Type=Application
                Categories=GTK;GNOME;Settings;
                StartupNotify=false
                X-GNOME-Autostart-enabled=false
                Hidden=true
            '';
        };
    };
}