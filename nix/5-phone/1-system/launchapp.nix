# `launchapp` -- run a graphical program from a shell that has no session.
#
# An ssh login to this phone has no Wayland display, no D-Bus session and no
# XDG_RUNTIME_DIR, so anything graphical started from one dies immediately, with
# an error about the display rather than about the environment. The three
# variables that fix it are always the same, and typing them out every time is
# how they end up wrong.
#
#     launchapp chromium
#     launchapp -d chromium --app=https://home-assistant.heimdall.technet
#
# The socket is discovered rather than assumed. `wayland-0` is the usual name
# but not a guarantee -- a compositor restarted while another still holds the
# name takes `wayland-1`, and hardcoding the first one then fails in a way that
# looks like the compositor is down.
#
# -d matters more here than it looks. Without it the program is a child of the
# ssh session and dies when that closes, which for a browser you meant to leave
# running on the phone is the opposite of what you asked for.
{ pkgs, ... }:
let
    launchapp = pkgs.writeShellApplication {
        name = "launchapp";
        runtimeInputs = with pkgs; [
            coreutils
            util-linux
        ];
        text = ''
            detach=0
            if [ "''${1:-}" = "-d" ] || [ "''${1:-}" = "--detach" ]; then
                detach=1
                shift
            fi

            if [ "$#" -eq 0 ] || [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
                cat >&2 <<'USAGE'
            Usage: launchapp [-d] COMMAND [ARGS...]

            Runs COMMAND inside the graphical session of the logged-in user,
            supplying the runtime directory, Wayland display and session bus that
            an ssh login does not have.

              -d, --detach   Outlive this shell; output goes to
                             $XDG_RUNTIME_DIR/launchapp-<command>.log
            USAGE
                exit 1
            fi

            runtime="/run/user/$(id -u)"
            if [ ! -d "$runtime" ]; then
                echo "launchapp: $runtime does not exist -- is the session running?" >&2
                exit 1
            fi

            # First socket that is actually a socket, so a stale lock file or a
            # renamed display does not send us to a dead one.
            display=""
            for candidate in "$runtime"/wayland-*; do
                case "$candidate" in
                    *.lock) continue ;;
                esac
                if [ -S "$candidate" ]; then
                    display="$(basename "$candidate")"
                    break
                fi
            done

            if [ -z "$display" ]; then
                echo "launchapp: no wayland socket in $runtime -- is phosh running?" >&2
                exit 1
            fi

            export XDG_RUNTIME_DIR="$runtime"
            export WAYLAND_DISPLAY="$display"
            export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus"

            if [ "$detach" -eq 1 ]; then
                log="$runtime/launchapp-$(basename "$1").log"
                setsid "$@" > "$log" 2>&1 &
                echo "launchapp: started $1 (log: $log)" >&2
                exit 0
            fi

            exec "$@"
        '';
    };
in
{
    environment.systemPackages = [ launchapp ];
}
