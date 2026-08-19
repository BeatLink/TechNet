{
    lib,
    pkgs,
    inputs,
    ...
}:
{
    boot = {
        kernelParams = [
            "plymouth.ignore-serial-consoles"
            "plymouth.force-scale=1"
        ];

        plymouth = {
            theme = lib.mkForce "nixos-mobile";
            themePackages = [ (pkgs.callPackage ./theme.nix { src = inputs.nixos-plymouth; }) ];
            # Volume up stands in for Esc, which toggles the splash and the boot log; plymouth takes only one such key, so volume down is unbound.
            extraConfig = "XkbExtraEscButton=0x1008ff13";
        };

        initrd.systemd = {
            paths."systemd-ask-password-plymouth".enable = false;
            services."systemd-ask-password-plymouth".enable = false;
        };
    };

    systemd.services.phosh.after = [ "plymouth-quit-wait.service" ];
}
