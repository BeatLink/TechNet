{pkgs, ...}: {
    services.mpd = {
        enable = true;
        dataDir = "/Storage/Services/MPD/Data";
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
    systemd.services = {
        mpd.serviceConfig.SupplementaryGroups = [ "pipewire" ];
        
        "mpd-set-volume" = {
            description = "Set MPD volume to 50% at boot";
            after = [ "mpd.service" "network-online.target" ];
            wants = [ "mpd.service" "network-online.target" ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = ''
                    ${pkgs.mpc}/bin/mpc volume 50
                '';
            };
            wantedBy = [ "multi-user.target" ];
        };
    };
}

# sudo setfacl -m u:mpd:rwx /Storage/
# sudo setfacl -m u:mpd:rwx /Storage/Services
# sudo setfacl -m u:mpd:rwx /Storage/Services/MPD