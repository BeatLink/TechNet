# Firefox
#
# The persistence and the enable are shared. What differs is per-host and set
# next to each host's other overrides, because programs.firefox merges across
# modules: Odin adds its native messaging hosts (firefoxpwa, keepassxc), and
# Thor swaps the package for the mobile build.
#
# mkDefault on the package so Thor can replace it without mkForce.
#
{ lib, pkgs, ... }:
{
    # mkDefault on both. Thor turns the module off entirely rather than swapping
    # the package: programs.firefox builds finalPackage by calling
    # `cfg.package.override { cfg = ...; }`, and firefox-mobile is a callPackage
    # of mobile-config.nix whose arguments are only runCommand, fetchFromGitLab,
    # wrapFirefox and firefox-unwrapped. Overriding it with `cfg` fails outright:
    #
    #     error: function 'anonymous lambda' called with unexpected argument 'cfg'
    #
    # The persistence below is deliberately outside the mkIf, so it applies on
    # both hosts whichever way Firefox itself is installed.
    programs.firefox = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.firefox;
    };

    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".cache/mozilla/firefox"
                    ".config/mozilla/firefox"
                    ".local/share/mozilla/firefox"
                ];
            };
        };
    };
}
