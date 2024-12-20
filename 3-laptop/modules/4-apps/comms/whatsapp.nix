{ config, pkgs, ... }: 
{
    home-manager.users.beatlink.home = {
        file = {

        };
        persistence."/Storage/Apps/Comms/WhatsApp/" = {
            files = [
                ".local/share/applications/whatsapp-private.desktop"
                ".local/share/applications/whatsapp.desktop"
                ".local/share/icons/whatsapp.png"
            ];
            allowOther = true;
        };
    };
}