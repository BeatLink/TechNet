# Firefox, phone build
#
# postmarketOS' mobile-config-firefox rather than the desktop build. It is not a
# fork: nixpkgs' `firefox-mobile` is wrapFirefox around the same
# firefox-unwrapped, with mobile-config-firefox's autoconfig, prefs, policies
# and userChrome/userContent CSS layered on. Touch-sized chrome, a bottom URL
# bar, no separate tab strip.
#
# Everything else -- enable, persistence -- is shared in 0-common/desktop, which
# marks the package mkDefault so this needs no mkForce. The profile paths are
# unchanged, so the persisted profile carries over.
#
{ pkgs, ... }:
{
    programs.firefox.package = pkgs.firefox-mobile;
}
