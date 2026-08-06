{ pkgs, ... }:
let
    stateDir = "/var/lib/app-preload";
    maxLockedFile = "2m";

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
in
{
    environment.systemPackages = [
        record
        preload
        lock
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

    systemd.timers.app-preload = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "2min";
            AccuracySec = "30s";
        };
    };
}
