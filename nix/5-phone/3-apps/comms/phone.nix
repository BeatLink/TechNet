{ pkgs, ... }:
{
    programs.calls.enable = true;

    # Optional but recommended. https://github.com/NixOS/nixpkgs/pull/162894
    systemd.services.ModemManager.serviceConfig.ExecStart = [
        "" # clear ExecStart from upstream unit file.
        "${pkgs.modemmanager}/sbin/ModemManager --test-quick-suspend-resume"
    ];

    # Routes call audio between earpiece, speaker and headset. gnome-calls asks
    # for it over the session bus but does not depend on it, so without this a
    # call connects and stays on whatever sink the desktop was already using --
    # audible from the speaker rather than the earpiece, with no way to switch.
    # It ships only a D-Bus service file, so being in the profile is all the
    # session bus needs to activate it on demand.
    environment.systemPackages = [ pkgs.callaudiod ];

}
