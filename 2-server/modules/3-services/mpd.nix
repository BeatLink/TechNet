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
                    #!/bin/sh
                    # Wait until MPD responds to mpc
                    for i in $(seq 1 30); do
                        if ${pkgs.mpc}/bin/mpc >/dev/null 2>&1; then
                            break
                        fi
                            sleep 1
                    done

                    # Set volume to 50%
                    ${pkgs.mpc}/bin/mpc volume 50

                    # Persist volume so MPD remembers it
                    ${pkgs.mpc}/bin/mpc save
                '';
            };
            wantedBy = [ "multi-user.target" ];
        };
    };
}

# sudo setfacl -m u:mpd:rwx /Storage/
# sudo setfacl -m u:mpd:rwx /Storage/Services
# sudo setfacl -m u:mpd:rwx /Storage/Services/MPD