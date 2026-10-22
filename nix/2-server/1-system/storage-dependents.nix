# Storage Dependents #################################################################################################################################
#
# The services on this host that keep their state under /Storage, each bound to the data pool's mount so none of them starts, or writes into the
# empty mountpoint, while the pool is missing.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Mount Dependencies #########################################################################################################################
        {
            systemd.services =
                lib.genAttrs
                    [
                        "atticd"
                        "blockurl"
                        "borg-compact-laptop-vorta"
                        "calibre-web-nextgen"
                        "calibre-web-nextgen-auto-zipper"
                        "calibre-web-nextgen-checksums"
                        "calibre-web-nextgen-ingest"
                        "calibre-web-nextgen-metadata"
                        "calibre-web-nextgen-preview-cache"
                        "esphome"
                        "freshrss-config"
                        "freshrss-updater"
                        "frigate"
                        "home-assistant"
                        "jackett"
                        "lnxlink"
                        "pihole-ftl"
                        "pihole-ftl-setup"
                        "pihole-gravity"
                        "qbittorrent"
                        "radicale"
                        "syncthing"
                        "traccar"
                        "trilium-server"
                        "unbound"
                        "unbound-root-hints"
                        "vlc-audio"
                        "x-monitor"
                        "x-monitor-import-vigil-db"
                    ]
                    (_: {
                        unitConfig.RequiresMountsFor = [ "/Storage" ];
                    });
        }
    ];
}
