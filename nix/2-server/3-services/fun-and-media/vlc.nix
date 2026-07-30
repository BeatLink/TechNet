{
    pkgs,
    config,
    ...
}:
{
    sops.secrets.vlc_env.sopsFile = "${config.technet.secrets.path}/vlc.yaml";
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
                User = "beatlink";
                Group = "audio";
                EnvironmentFile = config.sops.secrets.vlc_env.path;
                ExecStart = ''
                    ${pkgs.vlc}/bin/vlc \
                      -I telnet \
                      --telnet-host 127.0.0.1 \
                      --telnet-password "$VLC_TELNET_PASSWORD" \
                      --no-video \
                      --aout pipewire
                '';
                Restart = "always";
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "full";
                ProtectHome = "read-only";
                ProtectClock = true;
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                RestrictNamespaces = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                RestrictAddressFamilies = [
                    "AF_UNIX"
                    "AF_INET"
                ];
                LockPersonality = true;
                CapabilityBoundingSet = "";
                AmbientCapabilities = "";
                SystemCallArchitectures = "native";
                SystemCallFilter = [
                    "@system-service"
                    "~@privileged"
                ];
                ReadOnlyPaths = [
                    "/Storage/Files/Music"
                    "/Storage/Files/Sounds"
                ];
            };
            wantedBy = [ "multi-user.target" ];
        };
    };
}
