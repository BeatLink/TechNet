# Sleep ##############################################################################################################################################
#
# Suspend-to-RAM policy. Tow-Boot's crust firmware already gives the A64 a real `deep` state and resume works; what was missing was anything ever
# asking for it, so the phone stayed awake indefinitely with the screen off.
#

{ lib, pkgs, ... }:
let
    inherit (lib.gvariant) mkUint32;

    wifi_proc = "/proc/net/rtl8723cs/wld0";
    ethernet_ipv4_header = "-:-:-:-:-:-:-:-:-:-:-:-:08:00:-:-:-:-:-:-:-:-:-";
in
{
    config = lib.mkMerge [

        # Idle Suspend ###############################################################################################################################

        # logind drives this rather than gsd-power, whose idle timers never fire here: gnome-session fails to acquire an idle monitor under phosh
        # ("Failed to acquire idle monitor proxy ... Remote peer disconnected"), so its sleep-inactive-* timeouts are inert whatever they are set to.
        # phosh still sets the session idle hint that logind reads, which is the one piece of idle plumbing that works.
        #
        # An SSH or serial session counts as a session, so its own idle time gates this too -- a silent long job still wants `systemd-inhibit
        # --what=sleep`, because a closure copy cut off mid-way surfaces as "Broken pipe" rather than as a sleeping phone.
        {
            services.logind.settings.Login = {
                IdleAction = "suspend";
                IdleActionSec = "1min"; # Counted from the screen blanking, which phosh already holds off for 5 minutes of no input
            };
        }

        # Wi-Fi Wake Filter ##########################################################################################################################

        # WoWLAN on the rtl8723cs wakes on every packet to the phone by default; this narrows it to SSH over the LAN before each suspend.
        {
            systemd.services.wifi-wake-filter = {
                description = "Limit Wi-Fi wakeups to SSH before suspending";
                wantedBy = [ "sleep.target" ];
                before = [ "sleep.target" ];
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "wifi-wake-filter" ''
                        ${pkgs.coreutils}/bin/test -d ${wifi_proc} || exit 0

                        address=$(${pkgs.iproute2}/bin/ip -4 -o address show dev wld0 | ${pkgs.gawk}/bin/awk '{ split($4, a, "/"); print a[1]; exit }')
                        [ -n "$address" ] || exit 0
                        address_hex=$(printf '%02X:%02X:%02X:%02X' $(echo "$address" | ${pkgs.coreutils}/bin/tr . ' '))

                        # Magic packet, disconnect and firmware ARP replies, without the driver's catch-all TCP and ICMP patterns; this write also clears every pattern, so it goes first.
                        echo 13 > ${wifi_proc}/wow_wakeup_event

                        ${pkgs.wirelesstools}/bin/iwpriv wld0 wow_set_pattern clean
                        ${pkgs.wirelesstools}/bin/iwpriv wld0 wow_set_pattern "pattern=${ethernet_ipv4_header}:06:-:-:-:-:-:-:$address_hex:-:-:00:16"
                    '';
                };
            };
        }

        # Awake On Charger ###########################################################################################################################

        # External power holds an idle inhibitor, so the phone stays reachable while it charges; power from the keyboard case alone does not count.
        {
            systemd.services.awake-on-charger = {
                description = "Keep the phone awake while it is on external power";
                serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle --who=awake-on-charger --why=\"On external power\" ${pkgs.coreutils}/bin/sleep infinity";
            };

            systemd.services.awake-on-charger-sync = {
                description = "Start or stop awake-on-charger to match the power source";
                wantedBy = [ "multi-user.target" ];
                after = [ "pinephone-keyboard-sync.service" ];
                startLimitIntervalSec = 0;
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "awake-on-charger-sync" ''
                        read_or_zero() { ${pkgs.coreutils}/bin/cat "$1" 2>/dev/null || echo 0; }

                        usb_input=$(read_or_zero /sys/class/power_supply/axp20x-usb/online)
                        docked=$(read_or_zero /run/pinephone-keyboard-docked)
                        case_input=$(read_or_zero /sys/class/power_supply/ip5xxx-usb/present)

                        # With the case on, the phone's input is the case's own battery unless the case itself is plugged in.
                        if [ "$usb_input" = 1 ] && { [ "$docked" != 1 ] || [ "$case_input" = 1 ]; }; then
                            ${pkgs.systemd}/bin/systemctl start awake-on-charger.service
                        else
                            ${pkgs.systemd}/bin/systemctl stop awake-on-charger.service
                        fi
                    '';
                };
            };

            # The phone's own battery reports a change every second or so while the case is attached, which would start this unit nonstop.
            services.udev.extraRules = ''
                SUBSYSTEM=="power_supply", ACTION=="change", KERNEL!="axp20x-battery", RUN+="${pkgs.systemd}/bin/systemctl --no-block start awake-on-charger-sync.service"
            '';
        }

        # Check-In Wake ##############################################################################################################################

        # Wireguard traffic cannot wake the phone without waking it every few seconds, so on battery it wakes itself for Heimdall's deploys and Vigil.
        {
            systemd.timers.check-in-wake = {
                description = "Wake the phone every half hour to check in";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "*:00,30";
                    WakeSystem = true;
                    AccuracySec = "1s"; # The check-in monitors poll a minute after the slot, so the window must open on it
                };
            };

            systemd.services.check-in-wake = {
                description = "Hold the phone awake for a check-in window";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle --who=check-in-wake --why=\"Check-in window\" ${pkgs.coreutils}/bin/sleep 180";
                };
            };
        }

        # Caffeine ###################################################################################################################################

        # The quick setting inhibits idle, which holds the session idle hint low and so blocks the suspend above. Its stock intervals end in
        # 4294967295 -- once tapped the phone never sleeps again. Every interval here is finite so the toggle always expires on its own.
        {
            programs.dconf.profiles.user.databases = [
                {
                    settings."mobi/phosh/plugins/caffeine-quick-setting" = {
                        intervals = map mkUint32 [
                            300
                            900
                            1800
                            3600
                        ];
                        selected-index = mkUint32 1;
                    };
                }
            ];
        }
    ];
}
