{ config, inputs, lib, ... }:
let
    hn = config.networking.hostName;

    clevisDatasets = [
        "data-pool-${hn}/storage"
        "root-pool-${hn}/root"
    ];

    zfs = "${config.boot.zfs.package}/sbin/zfs";

    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " clevisDatasets}"
        attempts=80
        while [ -n "$remaining" ] && [ "$attempts" -gt 0 ]; do
            attempts=$((attempts - 1))
            still_locked=""
            for ds in $remaining; do
                status="$(${zfs} get -H -o value keystatus "$ds" 2>/dev/null || echo unavailable)"
                if [ "$status" = available ]; then
                    continue
                fi
                jwe="/etc/clevis/$ds.jwe"
                if [ -r "$jwe" ] && clevis decrypt < "$jwe" | ${zfs} load-key -L prompt "$ds" 2>/dev/null; then
                    echo "clevis-retry: unlocked $ds"
                    continue
                fi
                still_locked="$still_locked''${still_locked:+ }$ds"
            done
            remaining="$still_locked"
            [ -n "$remaining" ] || break
            sleep 15
        done
        if [ -n "$remaining" ]; then
            echo "clevis-retry: giving up, still locked:$remaining"
        else
            echo "clevis-retry: all clevis datasets unlocked"
        fi
    '';
in
{
    sops.secrets.clevis_key = {
        sopsFile = "${inputs.self}/secrets/2-server/clevis.yaml";
    };

    boot.initrd = {
        clevis = {
            enable = true;
            useTang = true;
            devices = {
                "data-pool-${hn}/storage".secretFile = config.sops.secrets.clevis_key.path;
                "root-pool-${hn}/root".secretFile = config.sops.secrets.clevis_key.path;
            };
        };

        systemd.services.clevis-retry = {
            description = "Keep retrying clevis/tang unlock while the boot waits";
            wantedBy = [ "initrd.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig = {
                Type = "simple";
                TimeoutStartSec = "infinity";
            };
            script = retryScript;
        };
    };

    systemd.network = {
        wait-online.anyInterface = lib.mkForce false;
        networks."01-wireguard".linkConfig.RequiredForOnline = "routable";
    };
}
