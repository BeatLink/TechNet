# Home Assistant as a WebKitGTK web app -- an A/B test, not a decision.
#
# This exists to answer one question with numbers instead of impressions: for
# the same site on the same phone, does WebKitGTK do better than Gecko?
#
# It is deliberately a second launcher rather than a replacement. The Firefox
# one in 0-common/desktop/4-apps/technet/home-assistant stays exactly as it is,
# so both can be opened back to back and compared. Nothing here changes what
# the phone does by default, and deleting this file removes the whole
# experiment.
#
# Why it is worth measuring rather than assuming. Firefox falls back to software
# WebRender here, because WebRender wants GLES 3.0 and the Mali-400 is GLES 2.0
# -- so every page is rasterised on CPU cores that are already the bottleneck.
# WebKitGTK is the other engine that ships for this platform, and whether its
# compositing path does anything with a GLES 2.0 GPU is not something to guess
# at. `gpu-usage` from 1-system/24-gpu-meter.nix is the instrument: if WebKitGTK
# genuinely renders on the GPU, GPU duty moves while a page scrolls and Firefox's
# does not.
#
# Epiphany is here as an engine host, not as a browser. It was tried as a
# browser earlier and rejected -- and separately measured slower to start than
# Firefox, 16.0s against 14.5s -- so this is not reopening that. Application mode
# is a different thing from browsing: no tabs, no address bar, its own profile
# and its own icon.
#
# Two things about the profile directory, both learned by it refusing to start.
#
# It has to exist before launch -- "--profile must be an existing directory when
# --application-mode is requested". The persistence entry below is what creates
# it: impermanence makes the source directory and bind-mounts it, which both
# satisfies that and keeps the Home Assistant login across the rollback of /.
#
# And its *name* is load-bearing. Epiphany derives the GApplication ID from the
# directory name and rejects anything without the org.gnome.Epiphany.WebApp_
# prefix:
#
#   Profile directory ... does not begin with required web app prefix
#     org.gnome.Epiphany.WebApp_
#   Failed to get GApplication ID from profile directory ...
#
# after which it aborts. The suffix becomes part of a D-Bus name, so it is
# HomeAssistant rather than home-assistant -- hyphens are not valid in one.
{ pkgs, ... }:
let
    profileName = "org.gnome.Epiphany.WebApp_HomeAssistant";
    profileDir = "/home/beatlink/.local/share/${profileName}";

    # Same host the Firefox launcher uses. Worth stating because the short form
    # -- homeassistant.heimdall.technet -- does not resolve at all; the name
    # with the hyphen is the one 2-server declares and the one that answers.
    url = "https://home-assistant.heimdall.technet";
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.epiphany ];

            persistence."/Storage/Apps/Core/EpiphanyWebApps" = {
                directories = [
                    ".local/share/${profileName}"
                ];
            };

            file.".local/share/applications/home-assistant-webkit.desktop".text = ''
                [Desktop Entry]
                Type=Application
                Name=Home Assistant (WebKit)
                Comment=Home Assistant on WebKitGTK, for comparison against Firefox
                Exec=${pkgs.epiphany}/bin/epiphany --application-mode --profile=${profileDir} ${url}
                Icon=org.gnome.Epiphany
                Terminal=false
                Categories=Network;
            '';
        };
    };
}
