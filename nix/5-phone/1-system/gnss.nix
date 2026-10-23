# GNSS
#
# Feeds the EG25's GNSS to geoclue straight from the modem's QMI location service, so a fix never depends on ModemManager or on a SIM being present.
# geoclue connects to the socket only while a client wants a location, and each connection starts its own GNSS session that ends when it closes.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    socket_path = "/run/gnss-nmea.sock";
    modem_device = "/dev/cdc-wdm0";

    nmea_stream = pkgs.writeShellApplication {
        name = "gnss-nmea";
        runtimeInputs = [
            pkgs.coreutils
            pkgs.gnused
            pkgs.libqmi
        ];
        text = ''
            # Through qmi-proxy, so the session shares the modem with ModemManager when it runs and spawns the proxy itself when it does not.
            qmi() {
                stdbuf -oL qmicli --device-open-proxy --device=${modem_device} "$@"
            }

            client_id=$(qmi --loc-start --client-no-release-cid | sed -n "s/.*CID: '\([0-9]*\)'.*/\1/p")
            [ -n "$client_id" ] || { echo "gnss-nmea: the modem started no location session" >&2; exit 1; }

            coproc follow { qmi --client-cid="$client_id" --client-no-release-cid --loc-follow-nmea; }
            follow_pid=$!

            trap 'kill "$follow_pid" 2> /dev/null; qmi --client-cid="$client_id" --loc-stop > /dev/null' EXIT
            trap 'exit 143' TERM

            # GLib ignores SIGPIPE, so qmicli would write into a closed socket forever; cat dies on the first such write and ends the session.
            cat <&"''${follow[0]}" || true
        '';
    };
in
{
    config = lib.mkMerge [

        # NMEA Socket ################################################################################################################################

        {
            systemd.sockets.gnss-nmea = {
                description = "GNSS NMEA stream for geoclue";
                wantedBy = [ "sockets.target" ];
                socketConfig = {
                    ListenStream = socket_path;
                    Accept = true;
                    SocketGroup = "geoclue";
                    SocketMode = "0660";
                };
            };

            systemd.services."gnss-nmea@" = {
                description = "GNSS NMEA stream for geoclue";
                serviceConfig = {
                    ExecStart = lib.getExe nmea_stream;
                    StandardInput = "socket";
                    StandardOutput = "socket";
                    StandardError = "journal";
                    IgnoreSIGPIPE = false; # The stream only ends, and GNSS only powers down, when a write to a closed socket kills it
                    ProtectSystem = "strict";
                    ProtectHome = true;
                    PrivateTmp = true;
                    NoNewPrivileges = true;
                };
            };
        }

        # Geoclue ####################################################################################################################################

        # The modem source would ask ModemManager to drive the same receiver, and with no SIM it never gets one to drive.
        {
            environment.etc."geoclue/conf.d/90-gnss.conf".text = lib.generators.toINI { } {
                network-nmea = {
                    enable = true;
                    nmea-socket = socket_path;
                };
                modem-gps.enable = false;
            };

            systemd.services.geoclue.restartTriggers = [
                config.environment.etc."geoclue/conf.d/90-gnss.conf".source
            ];
        }
    ];
}
