
{ config, pkgs, ... }: 
{
    home.file = {
        ".config/autostart/org.deluge_torrent.deluge.desktop".text = ''
            [Desktop Entry]
            Version=1.0
            Name=Deluge
            GenericName=BitTorrent Client
            X-GNOME-FullName=Deluge BitTorrent Client
            Comment=Download and share files over BitTorrent
            Keywords=torrent;magnet;sharing
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=deluge-gtk --file-forwarding org.deluge_torrent.deluge @@u %U @@
            Icon=org.deluge_torrent.deluge
            Terminal=false
            Type=Application
            Categories=Network;FileTransfer;P2P;GTK;
            StartupWMClass=deluge
            StartupNotify=true
            MimeType=application/x-bittorrent;x-scheme-handler/magnet;
            X-GNOME-UsesNotifications=true
            X-Desktop-File-Install-Version=0.26
            X-Flatpak=org.deluge_torrent.deluge
            X-GNOME-Autostart-enabled=true
            NoDisplay=false
            Hidden=false
            Name[en_US]=Deluge
            Comment[en_US]=Download and share files over BitTorrent
            X-GNOME-Autostart-Delay=30
        '';
    };
}