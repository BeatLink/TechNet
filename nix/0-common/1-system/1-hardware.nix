# Enable Fwupd for automatic firmware updates ################################################################################################
{ pkgs, ... }:
{
    services.fwupd.enable = true;
    systemd = {
        timers.fwupd-auto-update = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = "weekly";
                Persistent = true;
            };
        };
        services.fwupd-auto-update = {
            script = ''
                ${pkgs.fwupd}/bin/fwupdmgr refresh --force
                ${pkgs.fwupd}/bin/fwupdmgr update
            '';
            serviceConfig = {
                Type = "oneshot";
            };
        };
    };
}
