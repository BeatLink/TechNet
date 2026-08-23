# Boot Splash
#
# Halon's splash in place of the NixOS one that 0-common installs, so the machine wears one look from power on.
#

{
    lib,
    pkgs,
    inputs,
    ...
}:
{
    boot.plymouth = {
        theme = lib.mkForce "halon"; # nixos-plymouth's module sets the theme outright, so overriding it takes mkForce
        themePackages = [ inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-plymouth-theme ];
    };
}
