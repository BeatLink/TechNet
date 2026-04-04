{
    config,
    lib,
    pkgs,
    ...
}:
{
    services.alloy = {
        enable = true;
        extraFlags = [
            "--stability.level=generally-available"
            "--server.http.listen-addr=0.0.0.0:12345"
        ];
    };

    # Alloy uses a separate config file written in Alloy syntax (River).
    # NixOS's alloy module reads from the configPath option, defaulting
    # to a file you manage. We write it via environment.etc.
    environment.etc."alloy/config.alloy" = {
        mode = "0644";
        source = ./config.alloy;
    };

    # Point the alloy service at our config file
    systemd.services.alloy = {
        serviceConfig = {
            ExecStart = lib.mkForce (
                "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.alloy"
                + " --stability.level=generally-available"
                + " --server.http.listen-addr=0.0.0.0:12345"
            );

            # Allow alloy to read the journal
            SupplementaryGroups = [ "systemd-journal" ];

            # Secret injection — create /etc/alloy/secrets with:
            #   LOKI_PASSWORD=...
            #   PROMETHEUS_PASSWORD=...
            #   HOSTNAME=myhostname
            EnvironmentFile = lib.mkIf (builtins.pathExists /etc/alloy/secrets) [
                "/etc/alloy/secrets"
            ];
        };
    };

    # Open ports if Alloy receives OTLP from remote services
    # networking.firewall.allowedTCPPorts = [ 4317 4318 12345 ];

}
