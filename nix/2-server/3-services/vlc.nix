{
    pkgs,
    config,
    inputs,
    ...
}:
{
    networking.firewall = {
        allowedTCPPorts = [
            4212
            # 4213
        ];
    };
    sops.secrets.vlc_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    systemd.services = {
        vlc-audio = {
            description = "Headless VLC Media Player for Playing Audio from Home Assistant";
            after = [
                "network.target"
                "pipewire.service"
            ];
            wants = [
                "network.target"
                "pipewire.service"
            ];

            serviceConfig = {
                Type = "simple";
                User = "beatlink"; # Change to the user that has audio access
                Group = "audio";

                # Fetch the secret at runtime using environment file from sops-nix
                EnvironmentFile = config.sops.secrets.vlc_env.path;

                ExecStart = ''
                    ${pkgs.vlc}/bin/vlc \
                      -I telnet \
                      --telnet-password "$VLC_TELNET_PASSWORD" \
                      --no-video \
                      --aout pipewire
                '';
                Restart = "always";
            };
            wantedBy = [ "multi-user.target" ];
        };
        /*vlc-video = {
            description = "Converts USB Webcam Stream to RSTP for Home Security";
            after = [
                "network.target"
                "pipewire.service"
            ];
            wants = [
                "network.target"
                "pipewire.service"
            ];

            serviceConfig = {
                Type = "simple";
                User = "beatlink"; # Change to the user that has audio access
                Group = "beatlink";
                SupplementaryGroups = [
                    "audio"
                    "video"
                ];

                # Fetch the secret at runtime using environment file from sops-nix
                EnvironmentFile = config.sops.secrets.vlc_env.path;

                ExecStart = ''
                    ${pkgs.vlc}/bin/cvlc \
                    v4l2:///dev/video0:width=1280:height=720:fps=30 \
                    :input-slave=pulse:// \
                    --avcodec-hw=vaapi \
                    --sout "#transcode{vcodec=h264,acodec=mp4a,ab=128,samplerate=48000}:rtp{sdp=rtsp://10.100.100.1:4213/webcam}" \
                    --no-sout-all \
                    --sout-keep \
                    --sout-rtsp-user "$VLC_RTSP_USER" \
                    --sout-rtsp-pwd "$VLC_RTSP_PASS"
                '';
                Restart = "always";
            };
            wantedBy = [ "multi-user.target" ];
        };*/
    };
}
