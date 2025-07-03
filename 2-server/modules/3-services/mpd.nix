{config, ...}: {
    services.mpd = {
        enable = true;
        musicDirectory = "/Storage/Services/MPD/MusicFolder";
        extraConfig = ''
            audio_output {
                type "pipewire"
                name "PipeWire Output"
            }
        '';
        network.listenAddress = "any";          # if you want to allow non-localhost connections
        network.startWhenNeeded = true;         # systemd feature: only start MPD service upon connection to its socket
        user = "beatlink";
    };
    systemd.services.mpd.environment = {
        # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
        XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.beatlink.uid}"; # User-id must match above user. MPD will look inside this directory for the PipeWire socket.
    };
    fileSystems =  {
        "/Storage/Services/MPD/MusicFolder/Music" = {
            depends = [ "/Storage" ];
            device = "/Storage/Files/Music";
            fsType = "none";
            options = [ "bind" ];
        };
        "/Storage/Services/MPD/MusicFolder/Sounds" = {
            depends = [ "/Storage" ];
            device = "/Storage/Files/Sounds";
            fsType = "none";
            options = [ "bind" ];
        };
    };
}