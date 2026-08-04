# Nemo, laptop settings
#
# The module is shared in 0-common/desktop/4-apps/system/nemo. These are the two
# things that genuinely differ from the phone.
#
{ pkgs, ... }:
{
    technet.desktop.nemo = {
        extraPackages = with pkgs; [
            nemo-preview
            ffmpeg-full
            imagemagick
            gettext
        ];

        bookmarks = ''
            file:///Storage/Files/Documents Documents
            file:///Storage/Files/Downloads Downloads
            file:///Storage/Files/eBooks eBooks
            file:///Storage/Files/Games Games
            file:///Storage/Files/Music Music
            file:///Storage/Files/Pictures Pictures
            file:///Storage/Files/Projects Projects
            file:///Storage/Files/Sounds Sounds
            file:///Storage/Files/Videos Videos
            file:///Storage/Files/VMs VMs
            file:///Storage/Files/Backups Backups
            file:///Storage Storage
            sftp://beatlink@heimdall.technet/Storage Heimdall
            sftp://beatlink@ragnarok.technet/Storage Ragnarok
        '';
    };
}
