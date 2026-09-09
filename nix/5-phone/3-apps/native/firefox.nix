# Firefox, phone build
#
# postmarketOS' mobile-config-firefox rather than the desktop build. Not a fork: nixpkgs' `firefox-mobile`
# is wrapFirefox around the same firefox-unwrapped, with mobile-config-firefox's autoconfig, prefs,
# policies and userChrome/userContent CSS layered on. Touch-sized chrome, a bottom URL bar, no tab strip.
#
# The autoconfig is the part that matters and the part a plain pkgs.firefox loses: it sets
# toolkit.legacyUserProfileCustomizations.stylesheets, without which the profile's userChrome.css is read
# by nothing, and it regenerates that CSS when the Firefox version moves.
#
# Installed as a plain package rather than through programs.firefox, which derives finalPackage with
# `cfg.package.override { cfg = ...; }`; firefox-mobile is a callPackage taking only runCommand,
# fetchFromGitLab, wrapFirefox and firefox-unwrapped, so that override fails to evaluate.
#
# Expect it to start well and scroll badly: the root drive's crypto is accelerated now, but
# toolkit-comparison.nix records that the Mali-400 is GLES 2.0 and saturates on fill rate at 720x1440.
#
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.firefox-mobile ];

            # All four, because the card carries the pre-waypipe layout and Firefox picks between .mozilla and the XDG paths depending on how it is built
            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".mozilla"
                    ".cache/mozilla"
                    ".config/mozilla"
                    ".local/share/mozilla"
                ];
            };
        };
    };
}
