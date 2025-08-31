{ pkgs, config, ... }:

{
    sops.secrets.vlc_env.sopsFile = ../../secrets.yaml;

    systemd.services.cvlc = {
        description = "Headless VLC Media Player with PipeWire and RC password from sops-nix";
        after = [
            "network.target"
            "pipewire.service"
            "pipewire-pulse.service"
        ];
        wants = [
            "network.target"
            "pipewire.service"
            "pipewire-pulse.service"
        ];

        serviceConfig = {
            Type = "simple";
            User = "beatlink"; # Change to the user that has audio access
            Group = "audio";

            # Fetch the secret at runtime using environment file from sops-nix
            EnvironmentFile = config.sops.secrets.vlc_env.path;

            ExecStart = ''
                ${pkgs.vlc}/bin/vlc \
                  --intf telnet \
                  --telnet-host 127.0.0.1 \
                  --telnet-port 4212 \
                  --telnet-password "$VLC_TELNET_PASSWORD" \
                  --no-video \
                  --aout pipewire
            '';
            Restart = "always";
        };
        wantedBy = [ "multi-user.target" ];
    };
}
