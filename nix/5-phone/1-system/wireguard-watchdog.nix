# WireGuard watchdog #################################################################################################################################
#
# Thor's tunnel carries its DNS and, on mobile data, its whole default route, so a session that has silently stopped passing traffic looks like the
# phone is offline. NetworkManager cannot notice: a WireGuard device has no carrier to lose and NM does not read handshakes, so it stays "activated"
# over a dead session -- and with a dynamic-DNS endpoint the address the session was built against can stop being Heimdall's. Two hooks cover that:
# a poll loop for silent death, and a dispatcher script for the link changes NM does report.

{ pkgs, lib, ... }:
let
    profile = "TechNet Wireguard"; # The id nmcli matches on, which is not the "TechNet WireGuard" attribute name the keyfile is written under.
    peer = "10.100.100.1";
    interface = "wireguard0";

    interval = 15;
    failuresBeforeBounce = 4;
    settleAfterBounce = 45;

    # Keepalive makes a healthy session rekey about every two minutes, so anything older than this is a session no longer being answered.
    maxHandshakeAge = 180;

    binPath = lib.makeBinPath [
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.iputils
        pkgs.networkmanager
        pkgs.wireguard-tools
    ];

    # Shared by the poll loop and the dispatcher hook, which ask the same questions about the tunnel.
    probes = ''
        # True while some link that could carry the tunnel is up, which the never-default USB gadget is not.
        have_uplink() {
            nmcli -t -f TYPE,DEVICE connection show --active | grep -qvE '^(wireguard|loopback):|:usb0$'
        }

        # True while the kernel reports a handshake recent enough to prove Heimdall answered.
        session_alive() {
            local stamp
            stamp=$(wg show ${interface} latest-handshakes 2>/dev/null | awk 'NR == 1 { print $2 }')
            [ -n "$stamp" ] && [ "$stamp" -gt 0 ] || return 1
            [ $(( $(date +%s) - stamp )) -lt ${toString maxHandshakeAge} ]
        }

        # True while Heimdall answers through the tunnel.
        peer_reachable() {
            ping -c 1 -W 5 -I ${interface} ${peer} > /dev/null 2>&1
        }

        # Re-activates the profile, which re-resolves the endpoint's dynamic DNS on the way back up; capped waits so a dispatcher run cannot hang NM.
        bounce() {
            echo "wireguard-watchdog: bouncing ${profile}"
            nmcli -w 10 connection down "${profile}" > /dev/null 2>&1 || true
            sleep 2
            nmcli -w 20 connection up "${profile}" > /dev/null 2>&1 || echo "wireguard-watchdog: bring-up failed"
        }
    '';

    watchdog = pkgs.writeShellScript "wireguard-watchdog" ''
        set -u
        PATH=${binPath}:$PATH

        ${probes}

        failures=0
        while :; do
            sleep ${toString interval}

            # A fresh handshake is proof of a live session, so an unanswered ping is Heimdall's problem rather than the tunnel's.
            if ! have_uplink || peer_reachable || session_alive; then
                failures=0
                continue
            fi

            failures=$((failures + 1))
            echo "wireguard-watchdog: ${peer} unreachable and no recent handshake ($failures/${toString failuresBeforeBounce})"
            [ "$failures" -ge ${toString failuresBeforeBounce} ] || continue

            bounce
            failures=0
            sleep ${toString settleAfterBounce}
        done
    '';

    # Runs on every dispatcher event; $1 is the interface and $2 the action.
    dispatcher = pkgs.writeShellScript "wireguard-on-link-change" ''
        set -u
        PATH=${binPath}:$PATH

        ${probes}

        [ "$2" = "up" ] || exit 0
        case "$1" in
            ${interface} | lo | usb0) exit 0 ;;
        esac

        # The tunnel roams across links on its own, so this is only for the cases it cannot: a profile that never came up, and an endpoint whose
        # address belongs to the network just left.
        nmcli -t -f NAME connection show --active | grep -qxF "${profile}" && session_alive && exit 0

        echo "wireguard-watchdog: $1 came up without a live tunnel"
        bounce
    '';
in
{
    # Silent death ---------------------------------------------------------------------------------------------------------------------------------
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

    # Link changes ---------------------------------------------------------------------------------------------------------------------------------
    networking.networkmanager.dispatcherScripts = [
        {
            source = dispatcher;
            type = "basic";
        }
    ];
}
