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
        };

        initrd.systemd = {
            paths."systemd-ask-password-plymouth".enable = false;
            services."systemd-ask-password-plymouth".enable = false;
        };
    };

    systemd.services.phosh.after = [ "plymouth-quit-wait.service" ];
}
