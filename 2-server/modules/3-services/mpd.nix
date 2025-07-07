{
    services.mpd = {
        enable = true;
        dataDir = "/Storage/Services/MPD/Data";
        user = "beatlink";
        extraConfig = ''
            audio_output {
                type "pipewire"
                name "MPD PipeWire Output"
            }
        '';
        network.listenAddress = "any";          # if you want to allow non-localhost connections
    };
    networking.firewall = {
        allowedTCPPorts = [ 6600 ];
    };
    systemd.services.mpd.environment = {
        XDG_RUNTIME_DIR = "/run/user/1000";
    };
}

# sudo setfacl -m u:mpd:rwx /Storage/
# sudo setfacl -m u:mpd:rwx /Storage/Services
# sudo setfacl -m u:mpd:rwx /Storage/Services/MPD