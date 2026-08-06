# Which datasets the ARC is allowed to keep file data for.
#
# /Storage is bulk data that is read once and never re-read, so caching it only
# pushes out things that are.
#
# /nix is deliberately left at `all`, and the value is set rather than left
# alone because the property persists on the dataset once written.
#
# It was worth trying `metadata` there. ZFS serves mmap through the page cache
# while keeping its own ARC copy, so every library that 31-app-preload locks is
# held twice, and `metadata` drops the second copy. Measured on a quiet phone,
# four cold Epiphany launches each with the page locks up:
#
#     primarycache=all        13078 17009 17347 17951   mean 16.3s
#     primarycache=metadata   15424 15750 16852 27020   mean 18.8s
#
# The ranges overlap and the medians go the other way -- no real difference.
# And the duplication was not costing anything to begin with: across the same
# session the ARC moved 1331 -> 1008 -> 279 -> 168 MiB on its own as the locks
# and the apps asked for memory. It yields under pressure by itself, so the
# second copy is free in practice, while still covering the ~500 MiB of
# Epiphany's set that is not locked and every app with no profile at all.
#
{ config, ... }:
let
    host = config.networking.hostName;
in
{
    systemd.services.zfs-cache-policy = {
        description = "Set which datasets the ARC may cache file data for";
        wantedBy = [ "multi-user.target" ];
        after = [ "zfs-import.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        path = [ config.boot.zfs.package ];
        script = ''
            set -u

            set -- \
                "data-pool-${host}/storage" metadata \
                "root-pool-${host}/root/nix" all

            while [ "$#" -ge 2 ]; do
                dataset="$1"
                policy="$2"
                shift 2

                if zfs list -H -o name "$dataset" >/dev/null 2>&1; then
                    zfs set "primarycache=$policy" "$dataset"
                    echo "$dataset: primarycache=$policy"
                else
                    echo "$dataset: absent, skipped"
                fi
            done
        '';
    };
}
