# Mobile data
#
# FLOW Jamaica, operator id 338180.
#
# The APN is `ppinternet`, taken from the initial EPS bearer the network itself
# assigned when the modem attached:
#
#     sudo mmcli -b 0
#     Properties | apn: ppinternet
#                | ip type: ipv4
#
# Worth recording where it came from, because the usual source is wrong here:
# mobile-broadband-provider-info has no entry for 338180. Its Jamaica section
# lists Cable & Wireless at 338020 with apn `wap` and Digicel at 338050, neither
# of which is this SIM. FLOW is Cable & Wireless rebranded onto a newer network
# code the database has not caught up with.
#
# The SIM PIN comes from the same sops environment file the WiFi PSKs and the
# WireGuard key use -- NetworkManager substitutes $VARIABLES in profile values
# from `ensureProfiles.environmentFiles`, so the PIN is never written into the
# nix store or the repo. Add it with:
#
#     sops secrets/5-phone/networkmanager.yaml
#     # under networkmanager_env_file, alongside the others:
#     THOR_SIM_PIN=<pin>
#
# NetworkManager only offers that PIN when it activates this profile, and the
# profile is `autoconnect = false`, so at boot nothing presents it: the modem
# comes up locked and stays there. The unlock service below is what answers it.
#
# Until the 2026-08-17 firmware flash the modem held the PIN itself and unlocked
# a few seconds into every boot with no help from the host; the replacement
# firmware does not, and re-entering the PIN by hand does not re-arm it.
#
# If a prompt is wanted instead -- so the PIN is never at rest on the device --
# drop the `pin` line and the service, and set `pin-flags = 2`, which makes NM
# ask the session's secret agent, and phosh will put up a dialog after login.
#
{ config, pkgs, ... }:
{
    networking.networkmanager.ensureProfiles.profiles."FLOW" = {
        connection = {
            id = "FLOW";
            uuid = "3f1a6c74-9e2b-4d58-b0a7-5c8e1f2d9a43";
            type = "gsm";
            # Data is opt-in per session; the modem still registers, so calls and SMS are unaffected.
            autoconnect = false;
        };

        gsm = {
            apn = "ppinternet";
            pin = "$THOR_SIM_PIN";
        };

        ipv4.method = "auto";

        # The bearer reports ip type ipv4, so v6 is left as may-fail rather than
        # required -- an ipv6 = auto that never completes would hold the
        # connection in "connecting" indefinitely.
        ipv6 = {
            method = "auto";
            may-fail = true;
        };
    };

    # SIM unlock #####################################################################################################################################

    systemd.services.sim-unlock = {
        description = "Unlock the SIM with the stored PIN";
        wantedBy = [ "multi-user.target" ];

        # ModemManager exposes the modem tens of seconds after it starts, and only once eg25-manager has powered the radio, so the wait below is the
        # real ordering -- these two only keep this from running before either exists.
        after = [
            "ModemManager.service"
            "eg25-manager.service"
        ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "sim-unlock" ''
                # Sourced rather than declared as an EnvironmentFile, so this reads the file exactly as NetworkManager and the manual unlock do.
                env_file=${config.sops.secrets.networkmanager_env_file.path}
                if [ -r "$env_file" ]; then
                    set -a
                    . "$env_file"
                    set +a
                fi

                if [ -z "''${THOR_SIM_PIN:-}" ]; then
                    echo "sim-unlock: THOR_SIM_PIN is not in the environment file, nothing to send"
                    exit 0
                fi

                # Two minutes: a cold boot has taken over a minute to get from eg25-manager's power-on sequence to a modem on the bus.
                for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
                    keys=$(${pkgs.modemmanager}/bin/mmcli -m any -K 2>/dev/null) || {
                        ${pkgs.coreutils}/bin/sleep 2
                        continue
                    }

                    required=$(printf "%s\n" "$keys" | ${pkgs.gnused}/bin/sed -n "s/^modem.generic.unlock-required *: *//p")
                    # The PIN goes to the SIM object, not the modem: `mmcli -m any --pin` answers "no SIM was specified" and never reaches the card.
                    sim=$(printf "%s\n" "$keys" | ${pkgs.gnused}/bin/sed -n "s/^modem.generic.sim *: *//p")

                    case "$required" in
                        sim-pin)
                            if [ -z "$sim" ] || [ "$sim" = "--" ]; then
                                ${pkgs.coreutils}/bin/sleep 2
                                continue
                            fi
                            # Output is dropped rather than logged, because mmcli echoes the arguments it was given back in its error text.
                            if ${pkgs.modemmanager}/bin/mmcli -i "$sim" --pin="$THOR_SIM_PIN" > /dev/null 2>&1; then
                                echo "sim-unlock: SIM unlocked"
                                exit 0
                            fi
                            # One attempt only. Retrying a PIN the SIM has already rejected walks the counter down to the PUK.
                            echo "sim-unlock: the SIM refused the stored PIN, not retrying"
                            exit 1
                            ;;
                        "" | "--")
                            # The modem is on the bus but has not read the card yet, which is not the same as a card that wants no PIN.
                            ;;
                        *)
                            # Anything else, sim-pin2 included, is a lock this service has no business answering.
                            echo "sim-unlock: no SIM PIN required (unlock-required: $required)"
                            exit 0
                            ;;
                    esac

                    ${pkgs.coreutils}/bin/sleep 2
                done

                echo "sim-unlock: no modem appeared"
                exit 0
            '';
        };
    };
}
