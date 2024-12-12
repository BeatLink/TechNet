{ config, pkgs, ... }: 
{
    home-manager.users.beatlink.home.file = {
        ".local/share/applications/whatsapp-private.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=WhatsApp (Private)
            Comment=""
            Icon=whatsapp
            Exec=flatpak run org.mozilla.firefox "ext+container:name=Private&url=https://web.whatsapp.com"
            Categories=Network;InstantMessaging
            PrefersNonDefaultGPU = false;
            Terminal=false
        '';
        
        ".local/share/applications/whatsapp.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=WhatsApp
            Comment=""
            Icon=whatsapp
            Exec=flatpak run org.mozilla.firefox https://web.whatsapp.com
            Categories=Network;InstantMessaging
            PrefersNonDefaultGPU = false;
            Terminal=false
        '';        
    };
}