{
    services.prometheus.exporters.node = {
        enable = true;
        port = 9000;
        # For the list of available collectors, run, depending on your install:
        # - Flake-based: nix run
        # - Classic: nix-shell -p prometheus-node-exporter --run "node_exporter --help"
        enabledCollectors = [
            "ethtool"
            "softirqs"
            "systemd"
            "tcpstat"
            "wifi"
            "zfs"
        ];
        # You can pass extra options to the exporter using `extraFlags`, e.g.
        # to configure collectors or disable those enabled by default.
        # Enabling a collector is also possible using "--collector.[name]",
        # but is otherwise equivalent to using `enabledCollectors` above.
        extraFlags = [
            "--collector.ntp.protocol-version=4"
            "--no-collector.mdadm"
        ];
    };

}
