# Enable Fwupd for automatic firmware updates ################################################################################################
{ pkgs, ... }:
{
    services.fwupd.enable = true;
    systemd = {
        # fwupd talks to polkit at startup but the upstream unit does not order
        # itself after it -- it carries only dbus.socket, dbus-broker.service and
        # systemd-tmpfiles-setup.service. Activation restarts both, so fwupd can
        # call StartServiceByName for polkit while polkit is still coming back,
        # and give up:
        #
        #     Failed to load daemon: failed to load authority: Error initializing
        #       authority: Error calling StartServiceByName for
        #       org.freedesktop.PolicyKit1: Timeout was reached
        #
        # Not slowness -- polkit takes about four seconds here, against a 25
        # second D-Bus timeout. It is a race, and only Thor is slow enough to
        # lose it consistently, which is why this went unnoticed on the others.
        #
        # It matters beyond fwupd itself: switch-to-configuration returns
        # non-zero when any unit fails to start, and nixos-rebuild reports that
        # as "did you forget to use --ask-elevate-password?" -- so a failed
        # firmware daemon made several successful deploys look like auth
        # failures.
        services.fwupd = {
            after = [ "polkit.service" ];
            wants = [ "polkit.service" ];
        };

        services.fwupd-refresh = {
            after = [ "fwupd.service" ];
            wants = [ "fwupd.service" ];
        };

        timers.fwupd-refresh.timerConfig = {
            Persistent = false;
            OnBootSec = "15min";
        };

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
