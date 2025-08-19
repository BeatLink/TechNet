{ pkgs, modulesPath, ... }:
{
    imports = [ 
        (modulesPath + "/installer/scan/not-detected.nix")
    ];
    services.fstrim.enable = true;
    services.fwupd.enable = true;

    systemd.timers.fwupd-auto-update = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
        };
    };

    systemd.services.fwupd-auto-update = {
        script = ''
            ${pkgs.fwupd}/bin/fwupdmgr refresh --force
            ${pkgs.fwupd}/bin/fwupdmgr update --no-reboot
        '';
        serviceConfig = {
            Type = "oneshot";
        };
    };

}