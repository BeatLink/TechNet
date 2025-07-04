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
    };
    systemd.services.mpd.serviceConfig.SupplementaryGroups = [ "pipewire" ];
    networking.firewall = {
        allowedUDPPorts = [ 6600 ];
        allowedTCPPorts = [ 6600 ];
    };
    systemd.tmpfiles.settings."MPD" = {                      # Sets the mount point permissions
        "/Storage/Services/MPD/MusicFolder" = {
            Z = {
                user = "mpd";
                group = "mpd";
                mode = "0770";
            };
        };
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