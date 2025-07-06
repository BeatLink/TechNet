{ config, ... }: {
    home-manager.users.beatlink = {
        services.mpd = {
            enable = true;
            musicDirectory = "/Storage/Services/MPD/Music";
            dataDir = "/Storage/Services/MPD/Data";
            extraConfig = ''
                audio_output {
                    type "pipewire"
                    name "PipeWire Output"
                }
            '';
            network = {
                listenAddress = "any";          # if you want to allow non-localhost connections
                port = 21280;
            };
        };
        systemd.user.services.mpd.environment = {
            # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
            XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.beatlink.uid}"; # User-id must match above user. MPD will look inside this directory for the PipeWire socket.
        };
    };
    networking.firewall = {
        allowedTCPPorts = [ 21280 ];
    };
    fileSystems =  {
        "/Storage/Services/MPD/Music/Music" = {
            depends = [ "/Storage" ];
            device = "/Storage/Files/Music";
            fsType = "none";
            options = [ "bind" ];
        };
        "/Storage/Services/MPD/Music/Sounds" = {
            depends = [ "/Storage" ];
            device = "/Storage/Files/Sounds";
            fsType = "none";
            options = [ "bind" ];
        };
    };
}