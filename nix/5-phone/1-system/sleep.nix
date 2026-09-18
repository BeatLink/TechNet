# Sleep ##############################################################################################################################################
#
# Suspend-to-RAM policy. Tow-Boot's crust firmware already gives the A64 a real `deep` state and resume works; what was missing was anything ever
# asking for it, so the phone stayed awake indefinitely with the screen off.
#

{ lib, ... }:
let
    inherit (lib.gvariant) mkUint32;
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
                IdleActionSec = "5min";
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
