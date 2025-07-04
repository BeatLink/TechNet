{
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
    };
    networking.firewall = {
        allowedTCPPorts = [ 21280 ];
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