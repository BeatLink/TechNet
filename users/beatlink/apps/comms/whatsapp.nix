{ config, pkgs, ... }: 
{
    home.file = {
        ".local/share/applications/WhatsApp (Private).desktop".text = ''
            [Desktop Entry]
            Name=WhatsApp (Private)
            Exec=firefox 'ext+container:name=Private&url=https://web.whatsapp.com'
            Comment=
            Terminal=false
            PrefersNonDefaultGPU=false
            Icon=whatsapp
            Type=Application
        '';

    home.file = {
        ".local/share/applications/WhatsApp.desktop".text = ''
            [Desktop Entry]
            Name=WhatsApp
            Exec=firefox https://web.whatsapp.com
            Comment=
            Terminal=false
            PrefersNonDefaultGPU=false
            Icon=whatsapp
            Type=Application
        '';
    };
}