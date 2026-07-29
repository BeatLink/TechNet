{ config, lib, pkgs, ... }:
let
    gate = pkgs.writeShellScript "tang-session-gate" ''
        set -u

        SYSTEMCTL=${pkgs.systemd}/bin/systemctl
        GDBUS=${pkgs.glib}/bin/gdbus

        start_tang() {
            $SYSTEMCTL start tangd.socket 2>/dev/null || true
        }

        stop_tang() {
            $SYSTEMCTL stop tangd.socket 2>/dev/null || true
        }

        apply() {
            case "$1" in
                true)  echo "tang-gate: session locked, stopping tang"; stop_tang ;;
                false) echo "tang-gate: session unlocked, starting tang"; start_tang ;;
            esac
        }

        active="$($GDBUS call --session \
            --dest org.cinnamon.ScreenSaver \
            --object-path /org/cinnamon/ScreenSaver \
            --method org.cinnamon.ScreenSaver.GetActive 2>/dev/null)"
        case "$active" in
            *true*)  apply true ;;
            *false*) apply false ;;
            *)       echo "tang-gate: screensaver not reachable, failing closed"; stop_tang ;;
        esac

        $GDBUS monitor --session \
            --dest org.cinnamon.ScreenSaver \
            --object-path /org/cinnamon/ScreenSaver 2>/dev/null |
        while read -r line; do
            case "$line" in
                *ActiveChanged*true*)  apply true ;;
                *ActiveChanged*false*) apply false ;;
            esac
        done

        echo "tang-gate: monitor exited, failing closed"
        stop_tang
        exit 1
    '';
in
{
    services.tang = {
        enable = true;
        ipAddressAllow = [
            "10.100.100.0/24"
            "192.168.0.0/24"
        ];
        listenStream = [
            "0.0.0.0:7654"
        ];
    };

    networking.firewall.allowedTCPPorts = [ 7654 ];

    environment.persistence."/Storage/System/Tang" = {
        directories = [
            {
                directory = "/var/lib/private/tang";
                mode = "0700";
            }
        ];
    };

    systemd.sockets.tangd = {
        wantedBy = lib.mkForce [ ];
        unitConfig.RequiresMountsFor = "/var/lib/private/tang";
    };

    systemd.services."tangd@".unitConfig = {
        RequiresMountsFor = "/var/lib/private/tang";
        ConditionDirectoryNotEmpty = "/var/lib/private/tang";
    };

    security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "tangd.socket" &&
                subject.user == "beatlink" &&
                subject.local && subject.active) {
                return polkit.Result.YES;
            }
        });
    '';

    systemd.user.services.tang-session-gate = {
        description = "Serve tang only while the desktop session is unlocked";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStart = "${gate}";
            ExecStopPost = "${pkgs.systemd}/bin/systemctl stop tangd.socket";
            Restart = "always";
            RestartSec = 2;
        };
    };
}
