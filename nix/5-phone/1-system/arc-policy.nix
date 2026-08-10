# Which datasets the ARC is allowed to keep file data for.
#
# Both are `all`, and the values are set rather than left alone because
# primarycache persists on the dataset once written.
#
# /Storage was `metadata` on the theory that it is bulk media read once, so
# caching it only evicts things that are re-read. That was wrong, because it is
# also where every application's profile and cache lives, and those are read
# constantly. Measured over 2226 files of WebKit cache, cold each time:
#
#                    first read   re-read   disk on re-read
#   metadata            6081ms     5553ms       24708 KiB
#   all                 6083ms      500ms           0 KiB
#
# Under `metadata` an application re-reads its own cache off the SD card every
# time it starts, forever. Under `all` the second read is served from the ARC.
#
# Worth reading alongside the /nix result below, because they look
# contradictory and are not. Libraries are mmapped, so they land in the page
# cache and primarycache genuinely does not matter -- measured, four cold
# Epiphany launches each side, no difference outside noise. Application data is
# read(), so it lives or dies by the ARC. Same knob, opposite answers, because
# the two are reached by different paths.
#
# It was worth trying `metadata` on /nix. ZFS serves mmap through the page cache
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
                "data-pool-${host}/storage" all \
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
