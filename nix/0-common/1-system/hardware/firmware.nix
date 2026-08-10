# Firmware Updates ###################################################################################################################################
#
# Runs fwupd and refreshes it on boot, with a weekly timer that applies whatever updates are available.
#

{ pkgs, ... }:
{
    services.fwupd.enable = true;

    systemd = {
        services = {
            fwupd = {
                after = [ "polkit.service" ]; # Without this fwupd races polkit on activation and fails the whole rebuild
                wants = [ "polkit.service" ];
            };

            fwupd-refresh = {
                after = [ "fwupd.service" ];
                wants = [ "fwupd.service" ];
            };

            fwupd-auto-update = {
                script = ''
                    ${pkgs.fwupd}/bin/fwupdmgr refresh --force
                    ${pkgs.fwupd}/bin/fwupdmgr update
                '';
                serviceConfig.Type = "oneshot";
            };
        };

        timers = {
            fwupd-refresh.timerConfig = {
                Persistent = false;
                OnBootSec = "15min";
            };

            fwupd-auto-update = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "weekly";
                    Persistent = true;
                };
            };
        };
    };
}
