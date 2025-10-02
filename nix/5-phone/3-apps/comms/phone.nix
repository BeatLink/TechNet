{ pkgs, ... }:
{
    programs.calls.enable = true;

    # Optional but recommended. https://github.com/NixOS/nixpkgs/pull/162894
    systemd.services.ModemManager.serviceConfig.ExecStart = [
        "" # clear ExecStart from upstream unit file.
        "${pkgs.modemmanager}/sbin/ModemManager --test-quick-suspend-resume"
    ];

}
