{ config, inputs, lib, ... }:
let
    hn = config.networking.hostName;

    clevisDatasets = [
        "data-pool-${hn}/storage"
        "root-pool-${hn}/root"
    ];

    zfs = "${config.boot.zfs.package}/sbin/zfs";

    clevis = "${config.boot.initrd.clevis.package}/bin/clevis";

    retryScript = ''
        set -u
        remaining="${lib.concatStringsSep " " clevisDatasets}"
        while [ -n "$remaining" ]; do
            still_locked=""
            for ds in $remaining; do
                status="$(${zfs} get -H -o value keystatus "$ds" 2>/dev/null || echo unavailable)"
                if [ "$status" = available ]; then
                    echo "clevis-retry: $ds already unlocked"
                    continue
                fi
                jwe="/etc/clevis/$ds.jwe"
                if [ -r "$jwe" ] && ${clevis} decrypt < "$jwe" | ${zfs} load-key -L prompt "$ds" 2>/dev/null; then
                    echo "clevis-retry: unlocked $ds"
                    continue
                fi
                still_locked="$still_locked''${still_locked:+ }$ds"
            done
            remaining="$still_locked"
            [ -n "$remaining" ] || break
            sleep 15
        done
        echo "clevis-retry: all clevis datasets unlocked"
    '';
in
{
    sops.secrets.clevis_key = {
        sopsFile = "${inputs.self}/secrets/1-backup-server/clevis.yaml";
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
            description = "Keep retrying clevis/tang unlock in the background until it succeeds";
            wantedBy = [ "sysinit.target" ];
            after = [ "systemd-modules-load.service" ];
            before = [ "zfs-import.target" ];
            unitConfig = {
                DefaultDependencies = "no";
                ConditionPathExists = "/etc/clevis";
            };
            serviceConfig = {
                Type = "simple";
                Restart = "on-failure";
                RestartSec = 15;
            };
            script = retryScript;
        };
    };
}
