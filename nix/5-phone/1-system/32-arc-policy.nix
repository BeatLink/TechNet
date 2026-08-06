# Which datasets the ARC is allowed to keep file data for.
#
# `metadata` is not "stop caching this dataset". ZFS serves mmap through the
# Linux page cache and keeps its own ARC copy of the same blocks, so a mapped
# library is held twice; `metadata` drops the second copy and leaves the page
# cache one. Executables and shared libraries are mmapped, so they still cache
# normally. What loses its cache is read() traffic, which for the store is icon
# and locale data rather than code.
#
# That is the whole point on /nix: 31-app-preload locks the pages apps actually
# fault in, and those locked pages live in the page cache. Leaving primarycache
# at `all` means the ARC holds a second, uncompressed-in-page-cache-anyway copy
# of exactly the bytes we already pinned.
#
{ config, ... }:
let
    host = config.networking.hostName;
in
{
    systemd.services.zfs-cache-policy = {
        description = "Keep the ARC off data the page cache already holds";
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs-import.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        path = [ config.boot.zfs.package ];
        script = ''
            set -u

            for dataset in "data-pool-${host}/storage" "root-pool-${host}/root/nix"; do
                if zfs list -H -o name "$dataset" >/dev/null 2>&1; then
                    zfs set primarycache=metadata "$dataset"
                    echo "$dataset: primarycache=metadata"
                else
                    echo "$dataset: absent, skipped"
                fi
            done
        '';
    };
}
