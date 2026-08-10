# `gpu-usage` -- GPU utilisation on a GPU that reports none.
#
# Nothing standard works here. lima implements no `drm-engine-*` keys in
# /proc/<pid>/fdinfo, so intel_gpu_top/nvtop-style tools see an empty device;
# its debugfs directory contains only `gem_names`; and devfreq is useless
# because the A64 declares exactly one GPU OPP (432MHz), so cur/min/max are all
# equal and trans_stat never moves.
#
# What does work is runtime PM. lima power-gates the GPU when idle, and the
# kernel keeps cumulative millisecond counters of both states, so the delta
# between two samples is a true busy/idle split.
#
# One caveat that matters when reading the output: autosuspend_delay_ms is 200,
# so the GPU is held active for 200ms after the last job finishes. A single
# frame therefore reads as 200ms of work. Short bursts overstate; sustained load
# is accurate. Compositing an otherwise still screen at 60fps will read ~100%
# and be nowhere near it -- compare against the since-boot figure, not against
# zero.
{ pkgs, ... }:
let
    gpu-usage = pkgs.writeShellApplication {
        name = "gpu-usage";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
            interval=''${1:-1}

            # Found by driver rather than hardcoded to card0: which minor lima
            # gets is not guaranteed, and sun4i-drm claims one of the two.
            power=
            for card in /sys/class/drm/card*/device; do
                if grep -qx 'DRIVER=lima' "$card/uevent" 2>/dev/null; then
                    power="$card/power"
                    break
                fi
            done

            if [ -z "$power" ] || [ ! -r "$power/runtime_active_time" ]; then
                echo "gpu-usage: no lima GPU exposing runtime PM found" >&2
                exit 1
            fi

            delay=$(cat "$power/autosuspend_delay_ms" 2>/dev/null || echo "?")
            a=$(cat "$power/runtime_active_time")
            s=$(cat "$power/runtime_suspended_time")

            echo "lima GPU, autosuspend ''${delay}ms -- bursts shorter than that read high"
            printf 'since boot  %3d%%   %ds busy / %ds idle\n' \
                "$(( a * 100 / (a + s + 1) ))" "$(( a / 1000 ))" "$(( s / 1000 ))"

            while true; do
                pa=$a
                ps=$s
                sleep "$interval"
                a=$(cat "$power/runtime_active_time")
                s=$(cat "$power/runtime_suspended_time")

                da=$(( a - pa ))
                ds=$(( s - ps ))
                pct=$(( da * 100 / (da + ds + 1) ))

                bar=
                for _ in $(seq 0 $(( pct / 4 ))); do bar="$bar#"; done
                printf '%5ss      %3d%%   %s\n' "$interval" "$pct" "$bar"
            done
        '';
    };
in
{
    environment.systemPackages = [ gpu-usage ];
}
