{ config, lib, pkgs, ... }:
{
    programs.plasma.kscreenlocker = {
        autoLock = true;
        timeout = 2;
        passwordRequired = true;
        passwordRequiredDelay = 1;
        lockOnResume = true;
        lockOnStartup = false;
        appearance = {
            alwaysShowClock = false;
            showMediaControls = false;
        };
    };
}