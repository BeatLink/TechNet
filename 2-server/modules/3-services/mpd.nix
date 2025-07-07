{
    services.mpd = {
        enable = true;
        /*musicDirectory = "/Storage/Services/MPD/Music";*/
        dataDir = "/Storage/Services/MPD/Data";
        extraConfig = ''
            audio_output {
                type "pulse"
                name "MPD PulseAudio Output"
            }
        '';
        network = {
            listenAddress = "any";          # if you want to allow non-localhost connections
        };
    };
    networking.firewall = {
        allowedTCPPorts = [ 6600 ];
    };
    users.users.mpd = {
        isSystemUser = true;
        extraGroups = [ "audio" ];
    };

    /*fileSystems =  {
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
    };*/
}

# sudo setfacl -m u:mpd:rwx /
# sudo setfacl -m u:mpd:rwx /Storage/
# sudo setfacl -m u:mpd:rwx /Storage/Services
# sudo setfacl -m u:mpd:rwx /Storage/Services/MPD