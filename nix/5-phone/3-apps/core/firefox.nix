# Firefox, phone build
#
# postmarketOS' mobile-config-firefox rather than the desktop build. It is not a
# fork: nixpkgs' `firefox-mobile` is wrapFirefox around the same
# firefox-unwrapped, with mobile-config-firefox 4.6.0's autoconfig, prefs,
# policies and userChrome/userContent CSS layered on. Touch-sized chrome, a
# bottom URL bar, no desktop tab strip.
#
# Installed as a plain package rather than through programs.firefox, which is
# turned off here. That module derives finalPackage with
# `cfg.package.override { cfg = ...; }`, and firefox-mobile is a callPackage of
# mobile-config.nix taking only runCommand, fetchFromGitLab, wrapFirefox and
# firefox-unwrapped -- so the override fails to evaluate. Nothing is lost: what
# the module adds is policies and native messaging hosts, and mobile-config
# ships its own policies.json while the phone wants no messaging hosts.
#
# Persistence is unaffected; it lives outside the module in 0-common/desktop and
# the profile format is unchanged, so the existing profile carries over.
#
{ pkgs, ... }:
{
    programs.firefox.enable = false;

    home-manager.users.beatlink.home.packages = [ pkgs.firefox-mobile ];
}
