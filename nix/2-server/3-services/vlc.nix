{
    pkgs,
    config,
    inputs,
    ...
}:
{
    networking.firewall = {
        allowedTCPPorts = [ 4212 ];
    };
    sops.secrets.vlc_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    systemd.services.vlc = {
        description = "Headless VLC Media Player with PipeWire and RC password from sops-nix";
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
}
