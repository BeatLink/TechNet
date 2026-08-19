# WireGuard watchdog #################################################################################################################################
#
# Thor's tunnel carries its DNS and, on mobile data, its whole default route, so a session that has silently stopped passing traffic looks like the
# phone is offline. NetworkManager will not notice: WireGuard has no link state to lose, and the peer endpoint is dynamic DNS, so the address the
# session was built against can simply stop being Heimdall's. This pings Heimdall through the tunnel and bounces the profile once it has been
# unreachable for a minute, which re-resolves the endpoint on the way back up.

{ pkgs, lib, ... }:
let
    profile = "TechNet Wireguard"; # The connection id inside the profile, which is what nmcli matches -- not the "TechNet WireGuard" attribute name the keyfile is written under.
    peer = "10.100.100.1";
    interface = "wireguard0";

    interval = 15;
    failuresBeforeBounce = 4;
    settleAfterBounce = 45;

    watchdog = pkgs.writeShellScript "wireguard-watchdog" ''
        set -u
        PATH=${
          lib.makeBinPath [
              pkgs.coreutils
              pkgs.iputils
              pkgs.iproute2
              pkgs.networkmanager
          ]
        }:$PATH

        # True while some link other than the tunnel is offering a default route.
        have_uplink() {
            ip route show default | grep -qv "dev ${interface}"
        }

        # True while Heimdall answers through the tunnel.
        peer_reachable() {
            ping -c 1 -W 5 -I ${interface} ${peer} > /dev/null 2>&1
        }

        failures=0
        while :; do
            sleep ${toString interval}

            if ! have_uplink; then
                failures=0
                continue
            fi

            if peer_reachable; then
                failures=0
                continue
            fi

            failures=$((failures + 1))
            echo "wireguard-watchdog: ${peer} unreachable ($failures/${toString failuresBeforeBounce})"
            [ "$failures" -ge ${toString failuresBeforeBounce} ] || continue

            echo "wireguard-watchdog: bouncing ${profile}"
            nmcli connection down "${profile}" > /dev/null 2>&1 || true
            sleep 2
            nmcli connection up "${profile}" > /dev/null 2>&1 || echo "wireguard-watchdog: bring-up failed, retrying next cycle"

            failures=0
            sleep ${toString settleAfterBounce}
        done
    '';
in
{
    # Watchdog -----------------------------------------------------------------------------------------------------------------------------------------
    systemd.services.wireguard-watchdog = {
        description = "Bounce the TechNet WireGuard tunnel when Heimdall stops answering";
        wantedBy = [ "multi-user.target" ];
        after = [ "NetworkManager.service" ];
        requires = [ "NetworkManager.service" ];

        serviceConfig = {
            Type = "simple";
            ExecStart = watchdog;
            Restart = "always";
            RestartSec = 10;
        };
    };
}
