{ lib, pkgs, ... }:
let
    stateDir = "/var/lib/app-preload";

    # Whole-file locking only pays off while the file is small. Anything above
    # this is locked page by page instead -- see pages/lockPages below.
    maxLockedFile = "2m";
    maxLockedFileBytes = 2 * 1024 * 1024;

    # Headroom over the recorded set, not a target. With Epiphany, Files,
    # Secrets, Settings and the three WebLaunch apps profiled, the merged set is
    # ~180 MiB against 813 MiB of file.
    #
    # Worth keeping ahead of the recordings rather than trimming to fit: the cap
    # drops whatever sorts last by path, which is arbitrary rather than least
    # useful, so a set that overruns loses random pages instead of cheap ones.
    maxLockedPages = 224 * 1024 * 1024;

    # App profile data, as opposed to the store. These live on
    # data-pool-Thor/storage, which is primarycache=metadata because it is
    # mostly bulk media -- so ZFS keeps no ARC copy of them and every launch
    # re-reads the lot. Warming them puts the pages in the page cache, which is
    # a separate cache from the ARC and unaffected by that policy.
    #
    # Only launch-critical profiles belong here. The rest of /Storage/Apps is
    # either dead -- Firefox and Chromium are 387M between them for apps that
    # were removed -- or not read at startup, like Waydroid's 1.9G image and
    # Syncthing's own data.
    warmDirs = [
        "/home/beatlink/.local/share/weblaunch"
        "/home/beatlink/.local/share/epiphany"
        "/home/beatlink/.config/epiphany"
    ];

    pages = pkgs.runCommandCC "preload-pages" { } ''
        mkdir -p $out/bin
        $CC -O2 -Wall -Wextra -o $out/bin/preload-pages ${./preload-pages.c}
    '';

    record = pkgs.writeShellApplication {
        name = "app-preload-record";
        runtimeInputs = [
            pkgs.strace
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
        ];
        text = ''
            if [ "$#" -lt 2 ]; then
                echo "usage: app-preload-record <name> <command> [args...]" >&2
                exit 1
            fi

            name="$1"
            shift

            seconds="''${APP_PRELOAD_SECONDS:-25}"
            trace="$(mktemp)"
            trap 'rm -f "$trace"' EXIT

            mkdir -p ${stateDir}

            strace -f -e trace=openat -o "$trace" "$@" >/dev/null 2>&1 &
            pid=$!
            sleep "$seconds"
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true

            grep -v ENOENT "$trace" \
                | sed -n 's|.*openat([^"]*"\(/nix/store/[^"]*\)".*= [0-9].*|\1|p' \
                | sort -u \
                | while IFS= read -r path; do
                    if [ -f "$path" ]; then
                        printf '%s\n' "$path"
                    fi
                done > ${stateDir}/"$name".list

            bytes="$(xargs -a ${stateDir}/"$name".list -d '\n' -r stat -Lc %s 2>/dev/null | awk '{s+=$1} END {print s+0}')"
            echo "$name: $(wc -l < ${stateDir}/"$name".list) files, $((bytes / 1048576)) MiB"
        '';
    };

    preload = pkgs.writeShellApplication {
        name = "app-preload";
        runtimeInputs = [
            pkgs.coreutils
            pkgs.findutils
            pkgs.vmtouch
        ];
        text = ''
            shopt -s nullglob

            present="$(mktemp)"
            trap 'rm -f "$present"' EXIT

            listed="$(cat ${stateDir}/*.list 2>/dev/null | wc -l || true)"

            for list in ${stateDir}/*.list; do
                while IFS= read -r path; do
                    if [ -f "$path" ]; then
                        printf '%s\n' "$path"
                    fi
                done < "$list"
            done | sort -u > "$present"

            found="$(wc -l < "$present")"

            if [ "$found" -gt 0 ]; then
                xargs -a "$present" -d "\n" -r vmtouch -q -f -t
            fi

            # Directories are walked live rather than recorded: a browser
            # profile is rewritten as the app runs, so a recorded file list goes
            # stale in a way the store never does.
            warm_dirs=(${lib.escapeShellArgs warmDirs})

            for dir in "''${warm_dirs[@]}"; do
                if [ -d "$dir" ]; then
                    vmtouch -q -t "$dir" || true
                    echo "warmed $dir"
                fi
            done

            echo "warmed $found of $listed recorded paths"

            if [ "$found" -lt $((listed / 2)) ]; then
                echo "over half the recorded paths are gone -- re-run app-preload-record" >&2
            fi
        '';
    };
    lock = pkgs.writeShellApplication {
        name = "app-preload-lock";
        runtimeInputs = [
            pkgs.coreutils
            pkgs.vmtouch
        ];
        text = ''
            shopt -s nullglob

            mapfile -t paths < <(cat ${stateDir}/*.list 2>/dev/null | sort -u | while IFS= read -r path; do
                if [ -f "$path" ]; then
                    printf '%s\n' "$path"
                fi
            done)

            if [ "''${#paths[@]}" -eq 0 ]; then
                echo "nothing recorded to lock" >&2
                exit 0
            fi

            echo "locking ''${#paths[@]} paths up to ${maxLockedFile} each"
            exec vmtouch -f -l -m ${maxLockedFile} "''${paths[@]}"
        '';
    };
    recordPages = pkgs.writeShellApplication {
        name = "app-preload-record-pages";
        runtimeInputs = [
            pkgs.coreutils
            pkgs.procps
            pages
        ];
        text = ''
            if [ "$#" -lt 2 ]; then
                echo "usage: app-preload-record-pages <name> <pattern>" >&2
                echo "  pattern matches process names, e.g. 'epiphany|WebKit'" >&2
                exit 1
            fi

            name="$1"
            shift

            # Deliberately not -f: the recorded paths appear in our own command
            # lines, so a full-cmdline match picks up vmtouch and preload-pages.
            mapfile -t pids < <(pgrep "$@")

            if [ "''${#pids[@]}" -eq 0 ]; then
                echo "no process matches '$*' -- start the app first" >&2
                exit 1
            fi

            mkdir -p ${stateDir}

            preload-pages record \
                --min-size ${toString maxLockedFileBytes} \
                --prefix /nix/store \
                "''${pids[@]}" | sort -u > ${stateDir}/"$name".pages

            bytes="$(awk -F'\t' '{s+=$3} END {print s+0}' ${stateDir}/"$name".pages)"
            echo "$name: $(wc -l < ${stateDir}/"$name".pages) ranges, $((bytes / 1048576)) MiB from ''${#pids[@]} processes"
        '';
    };

    lockPages = pkgs.writeShellApplication {
        name = "app-preload-lock-pages";
        runtimeInputs = [
            pkgs.coreutils
            pages
        ];
        text = ''
            shopt -s nullglob

            profiles=(${stateDir}/*.pages)

            if [ "''${#profiles[@]}" -eq 0 ]; then
                echo "nothing recorded to lock" >&2
                exit 0
            fi

            exec preload-pages lock \
                --max-total ${toString maxLockedPages} \
                "''${profiles[@]}"
        '';
    };

    status = pkgs.writeShellApplication {
        name = "app-preload-status";
        runtimeInputs = [
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gawk
            pkgs.systemd
            pkgs.vmtouch
        ];
        text = ''
            shopt -s nullglob

            printf '%-12s %7s %10s %10s %7s\n' app files size resident share

            for list in ${stateDir}/*.list; do
                name="$(basename "$list" .list)"

                mapfile -t paths < <(while IFS= read -r path; do
                    if [ -f "$path" ]; then
                        printf '%s\n' "$path"
                    fi
                done < "$list")

                if [ "''${#paths[@]}" -eq 0 ]; then
                    printf '%-12s %7s %10s %10s %7s\n' "$name" 0 - - -
                    continue
                fi

                vmtouch -f "''${paths[@]}" 2>/dev/null \
                    | awk -v name="$name" -v n="''${#paths[@]}" '
                        /Resident Pages/ {
                            split($3, p, "/")
                            r += p[1]; t += p[2]
                        }
                        END {
                            printf "%-12s %7d %9.0fM %9.0fM %6.0f%%\n",
                                name, n, t*4096/1048576, r*4096/1048576,
                                (t ? 100*r/t : 0)
                        }'
            done

            profiles=(${stateDir}/*.pages)

            if [ "''${#profiles[@]}" -gt 0 ]; then
                printf '\n%-12s %7s %10s\n' app ranges size
                for profile in "''${profiles[@]}"; do
                    name="$(basename "$profile" .pages)"
                    awk -F'\t' -v name="$name" '
                        {n++; s+=$3}
                        END {printf "%-12s %7d %9.0fM\n", name, n, s/1048576}
                    ' "$profile"
                done

                printf '%-12s %7s %9sM  (overlap between apps is locked once)\n' \
                    "= merged" "" \
                    "$(journalctl -u app-preload-lock-pages.service -n 20 --no-pager 2>/dev/null \
                        | awk '/locked [0-9]+ KiB/ {
                                   for (i = 1; i < NF; i++)
                                       if ($i == "locked") v = $(i + 1) / 1024
                               }
                               END {printf "%.0f", v}')"
            fi

            printf '\n%-12s %7s %10s %10s %7s\n' profile files size resident share
            warm_dirs=(${lib.escapeShellArgs warmDirs})

            for dir in "''${warm_dirs[@]}"; do
                [ -d "$dir" ] || continue
                vmtouch "$dir" 2>/dev/null | awk -v name="$(basename "$dir")" '
                    /Files:/          {files = $2}
                    /Resident Pages:/ {split($3, p, "/"); r = p[1]; t = p[2]}
                    END {
                        printf "%-12s %7d %9.0fM %9.0fM %6.0f%%\n",
                            name, files, t*4096/1048576, r*4096/1048576,
                            (t ? 100*r/t : 0)
                    }'
            done

            printf '\nlocked in memory : %s MiB\n' \
                "$(awk '/^Mlocked/ {printf "%.0f", $2/1024}' /proc/meminfo)"
            printf 'page locks       : %s\n' \
                "$(systemctl is-active app-preload-lock-pages.service)"
            printf 'warm pass        : %s (%s)\n' \
                "$(systemctl is-active app-preload.service)" \
                "$(systemctl show -P ExecMainStatus app-preload.service)"
            printf 'lock service     : %s\n' \
                "$(systemctl is-active app-preload-lock.service)"
            printf 'next warm pass   : %s\n' \
                "$(systemctl list-timers app-preload.timer --no-pager 2>/dev/null | awk 'NR==2 {print $1, $2, $3}')"
        '';
    };
in
{
    environment.systemPackages = [
        record
        recordPages
        preload
        lock
        lockPages
        status
        pages

        # The services carry their own copy through runtimeInputs, so this is
        # purely so that checking residency by hand is possible at all -- its
        # absence from PATH silently turned a warm pass in a benchmark into a
        # no-op that still reported a time.
        pkgs.vmtouch
    ];

    environment.persistence."/persistent".directories = [ stateDir ];

    systemd.tmpfiles.rules = [ "d ${stateDir} 0775 root beatlink -" ];

    systemd.services.app-preload = {
        description = "Read the files apps touch at startup back into the ARC";
        serviceConfig = {
            Type = "oneshot";
            Nice = 19;
            IOSchedulingClass = "idle";
            ExecStart = "${preload}/bin/app-preload";
        };
        unitConfig.ConditionPathExistsGlob = "${stateDir}/*.list";
    };

    systemd.services.app-preload-lock = {
        description = "Hold the small startup files in memory so nothing can evict them";
        wantedBy = [ "multi-user.target" ];
        after = [ "app-preload.service" ];
        unitConfig.ConditionPathExistsGlob = "${stateDir}/*.list";
        serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 30;
            LimitMEMLOCK = "infinity";
            Nice = 19;
            IOSchedulingClass = "idle";
            ExecStart = "${lock}/bin/app-preload-lock";
        };
    };

    # Separate from app-preload-lock because the two cover disjoint sets: that
    # one locks whole files under maxLockedFile, this one locks only the pages
    # a warm app actually faulted in out of the files above it.
    systemd.services.app-preload-lock-pages = {
        description = "Hold the used pages of the large libraries in memory";
        wantedBy = [ "multi-user.target" ];
        after = [ "app-preload.service" ];
        unitConfig.ConditionPathExistsGlob = "${stateDir}/*.pages";
        serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 30;
            LimitMEMLOCK = "infinity";
            Nice = 19;
            IOSchedulingClass = "idle";
            ExecStart = "${lockPages}/bin/app-preload-lock-pages";
        };
    };

    # Repeats, because the warmed pages are evictable by design -- only the
    # locked ones are guaranteed -- and nothing else would ever put them back.
    #
    # Affordable only because a repeat pass is cheap. Warming Home Assistant's
    # profile from cold costs 83.5s, since vmtouch faults 5504 files in one at a
    # time off the card; the same pass with the pages already resident is
    # 2.3s. So the hourly run is the 2.3s case almost always, and pays the long
    # one only after something has actually evicted the cache.
    systemd.timers.app-preload = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "1h";
            AccuracySec = "5min";
        };
    };
}
