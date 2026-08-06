{ pkgs, ... }:
let
    stateDir = "/var/lib/app-preload";

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
                xargs -a "$present" -d '\n' -r vmtouch -q -t
            fi

            echo "warmed $found of $listed recorded paths"

            if [ "$found" -lt $((listed / 2)) ]; then
                echo "over half the recorded paths are gone -- re-run app-preload-record" >&2
            fi
        '';
    };
in
{
    environment.systemPackages = [
        record
        preload
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

    systemd.timers.app-preload = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "2min";
            AccuracySec = "30s";
        };
    };
}
