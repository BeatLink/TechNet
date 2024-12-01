{ config, pkgs, ... }: 
{
    home.file = {
        ".config/autostart/org.gmusicbrowser.gmusicbrowser.desktop".text = ''
            [Desktop Entry]
            Name=gmusicbrowser
            Comment=Jukebox for large collections of mp3/ogg/flac/mpc
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=gmusicbrowser --file-forwarding org.gmusicbrowser.gmusicbrowser @@ %F @@
            Type=Application
            Icon=org.gmusicbrowser.gmusicbrowser
            Categories=Audio;AudioVideo;
            StartupNotify=true
            StartupWMClass=gmusicbrowser
            Comment[fr]=Jukebox pour de grandes collections de mp3/ogg/flac/mpc
            Actions=PlayPause;Next;Previous;LockArtist;LockAlbum
            X-Flatpak-RenamedFrom=gmusicbrowser.desktop;
            X-Flatpak=org.gmusicbrowser.gmusicbrowser
            X-GNOME-Autostart-enabled=true
            NoDisplay=false
            Hidden=false
            Name[en_US]=gmusicbrowser
            Comment[en_US]=Jukebox for large collections of mp3/ogg/flac/mpc
            X-GNOME-Autostart-Delay=30

            [Desktop Action PlayPause]
            Name=Play-Pause
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=gmusicbrowser org.gmusicbrowser.gmusicbrowser -cmd PlayPause
            Icon=media-playback-start-symbolic
            OnlyShowIn=Unity;

            [Desktop Action Next]
            Name=Next
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=gmusicbrowser org.gmusicbrowser.gmusicbrowser -cmd NextSong
            Icon=media-skip-backward-symbolic
            OnlyShowIn=Unity;

            [Desktop Action Previous]
            Name=Previous
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=gmusicbrowser org.gmusicbrowser.gmusicbrowser -cmd PrevSong
            Icon=media-skip-forward-symbolic
            OnlyShowIn=Unity;

            [Desktop Action LockArtist]
            Name=Toggle Artist Lock
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=gmusicbrowser org.gmusicbrowser.gmusicbrowser -cmd TogArtistLock
            OnlyShowIn=Unity;

            [Desktop Action LockAlbum]
            Name=Toggle Album Lock
            Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=gmusicbrowser org.gmusicbrowser.gmusicbrowser -cmd TogAlbumLock
            OnlyShowIn=Unity;
        '';
    };
}