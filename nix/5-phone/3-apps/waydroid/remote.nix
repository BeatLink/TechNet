# Waydroid on Odin #################################################################################################################################
#
# Hands this phone's Waydroid session to a waypipe display, so Android runs on this hardware and its windows appear on the other host. One container
# means one session: the phone gives Waydroid up for as long as the remote one holds it, and takes it back when that link ends.
#
{ pkgs, ... }:
let
    waydroidPackage = pkgs.waydroid-nftables;

    # What the panel is worth on a 1920x1080 laptop: the surface is these props one to one, and the density is Android's own tablet range
    remoteWidth = 1600;
    remoteHeight = 900;
    remoteDensity = 240;

    # Pins the container's panel size, which is read at the next container start rather than applied live.
    setSize = pkgs.writeShellScript "waydroid-remote-size" ''
        set -eu
        cfg=/var/lib/waydroid/waydroid.cfg
        prop=/var/lib/waydroid/waydroid_base.prop

        for pair in "persist.waydroid.width=$1" "persist.waydroid.height=$2"; do
            key=''${pair%%=*}
            value=''${pair#*=}

            if ${pkgs.gnugrep}/bin/grep -q "^$key" "$cfg"; then
                ${pkgs.gnused}/bin/sed -i "s|^$key.*|$key = $value|" "$cfg"
            else
                ${pkgs.gnused}/bin/sed -i "/^\[properties\]/a $key = $value" "$cfg"
            fi

            if ${pkgs.gnugrep}/bin/grep -q "^$key" "$prop"; then
                ${pkgs.gnused}/bin/sed -i "s|^$key=.*|$key=$value|" "$prop"
            else
                echo "$key=$value" >> "$prop"
            fi
        done
    '';

    # Takes the session for the calling waypipe display and gives it back when that display goes; `release` hands it back from anywhere.
    remote = pkgs.writeShellScriptBin "waydroid-remote" ''
        set -u
        export PATH=${
            pkgs.lib.makeBinPath [
                waydroidPackage
                pkgs.coreutils
                pkgs.gnused
                pkgs.procps
                pkgs.systemd
            ]
        }:$PATH
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"

        state="$XDG_RUNTIME_DIR/waydroid-remote"
        mkdir -p "$state"

        if [ "''${1:-}" = "release" ]; then
            pid=$(cat "$state/pid" 2>/dev/null) || exit 0
            kill "$pid" 2>/dev/null || true
            exit 0
        fi

        # An absolute WAYLAND_DISPLAY is a waypipe socket; a plain name is this phone's own session, which already has Waydroid
        case "''${WAYLAND_DISPLAY:-}" in
            /*) ;;
            *)
                echo "waydroid-remote: refusing to take the session outside a waypipe display" >&2
                exit 1
                ;;
        esac

        # A second launch joins the session already held rather than restarting Android under it
        if [ -e "$state/pid" ] && kill -0 "$(cat "$state/pid")" 2>/dev/null; then
            exec waydroid show-full-ui
        fi
        echo $$ > "$state/pid"

        # Waydroid reaches PulseAudio through a directory holding a `native` socket, where waypipe forwards a bare socket
        if [ -n "''${PULSE_SERVER:-}" ]; then
            mkdir -p "$state/pulse"
            ln -sfn "''${PULSE_SERVER#unix:}" "$state/pulse/native"
            export PULSE_RUNTIME_PATH="$state/pulse"
        fi

        phoneWidth=$(sed -n 's/^persist\.waydroid\.width *= *//p' /var/lib/waydroid/waydroid.cfg)
        phoneHeight=$(sed -n 's/^persist\.waydroid\.height *= *//p' /var/lib/waydroid/waydroid.cfg)

        session=
        finish() {
            trap - EXIT INT TERM HUP
            [ -n "$session" ] && kill "$session" 2>/dev/null
            waydroid session stop 2>/dev/null || true
            /run/wrappers/bin/sudo -n ${setSize} "$phoneWidth" "$phoneHeight"
            rm -f "$state/pid"
            systemctl --user start waydroid-session.service
        }
        trap finish EXIT INT TERM HUP

        systemctl --user stop waydroid-session.service
        /run/wrappers/bin/sudo -n ${setSize} ${toString remoteWidth} ${toString remoteHeight}

        waydroid session start &
        session=$!

        # Nothing Android-side answers until the container finishes booting, which is minutes from cold on this hardware
        (
            for _ in $(seq 1 60); do
                [ "$(/run/wrappers/bin/sudo -n waydroid shell -- getprop sys.boot_completed 2>/dev/null | tr -dc '0-9')" = "1" ] && break
                sleep 5
            done

            /run/wrappers/bin/sudo -n waydroid shell -- sh -c '
                wm size reset
                wm density ${toString remoteDensity}
                settings put system user_rotation 0
            ' > /dev/null

            waydroid show-full-ui
        ) &

        # sshd leaves its command running when a link drops, so a reparent to init is the only sign that the display this session draws on is gone
        (
            while [ "$(ps -o ppid= -p $$ | tr -dc '0-9')" != 1 ]; do
                sleep 5
            done
            kill $$ 2>/dev/null || true
        ) &

        wait "$session"
    '';
in
{
    environment.systemPackages = [ remote ];
}
