# Waydroid Boot State ################################################################################################################################
#
# Publishes whether Android has finished booting to /run/waydroid-state/android, readable by the waydroid group, so a monitor can see it without sudo.
#
{ lib, pkgs, ... }:
let
    # Writes "booting <pid> <since>", "booted <pid> <since>" or "stopped", where pid is the container's init and since is when that state began.
    publisher = pkgs.writeShellScript "waydroid-boot-state" ''
        set -u
        lxc="-P /var/lib/waydroid/lxc -n waydroid"
        booted=
        seen=
        since=
        last=

        publish() {
            [ "$1" = "$last" ] && return
            printf '%s\n' "$1" > /run/waydroid-state/.android && mv /run/waydroid-state/.android /run/waydroid-state/android
            last=$1
        }

        while true; do
            info=$(lxc-info $lxc -s -p 2>/dev/null)
            state=$(printf '%s\n' "$info" | awk '/^State:/ { print $2 }')
            pid=$(printf '%s\n' "$info" | awk '/^PID:/ { print $2 }')

            case "$state" in
                RUNNING)
                    if [ "$pid" != "$booted" ]; then
                        [ "$pid" = "$seen" ] || { seen=$pid; since=$(date +%s); }
                        if [ "$(timeout 10 lxc-attach $lxc --clear-env -- /system/bin/getprop sys.boot_completed 2>/dev/null | tr -dc 0-9)" = 1 ]; then
                            booted=$pid
                            publish "booted $pid $(date +%s)"
                        else
                            publish "booting $pid $since"
                        fi
                    fi
                    ;;
                # Attaching to a frozen container hangs until it thaws, and Android only asks to be frozen once it is up.
                FROZEN) ;;
                *)
                    booted=
                    seen=
                    publish stopped
                    ;;
            esac

            if [ -n "$booted" ]; then sleep 30; else sleep 5; fi
        done
    '';
in
{
    config = lib.mkMerge [

        # Publisher ##################################################################################################################################
        {
            systemd.services.waydroid-boot-state = {
                description = "Publish whether Android has finished booting";
                wantedBy = [ "multi-user.target" ];
                after = [ "waydroid-container.service" ];
                path = [
                    pkgs.coreutils
                    pkgs.gawk
                    pkgs.lxc
                ];
                serviceConfig = {
                    ExecStart = publisher;
                    Group = "waydroid";
                    RuntimeDirectory = "waydroid-state";
                    RuntimeDirectoryMode = "0750";
                    Restart = "always";
                    RestartSec = 10;
                };
            };
        }

        # Readers ####################################################################################################################################
        {
            users.groups.waydroid = { };

            services.vigil-agent.extraGroups = [ "waydroid" ];
        }
    ];
}
