# Firefox, phone build
#
{ pkgs, ... }:
let
    extraPrefs = ''
        pref("gfx.webrender.enabled", false);
        pref("gfx.webrender.software", true);
        pref("layers.acceleration.disabled", true);
        pref("webgl.disabled", true);

        pref("browser.sessionhistory.max_total_viewers", 0);
        pref("browser.tabs.unloadOnLowMemory", true);
        pref("browser.cache.memory.capacity", 32768);

        pref("browser.cache.disk.enable", false);
        pref("browser.sessionstore.interval", 300000);

        pref("browser.startup.homepage", "about:blank");
        pref("browser.newtabpage.activity-stream.feeds.topsites", false);
        pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
        pref("toolkit.telemetry.enabled", false);
        pref("datareporting.healthreport.uploadEnabled", false);
        pref("app.shield.optoutstudies.enabled", false);
        pref("extensions.pocket.enabled", false);
    '';

    firefox = pkgs.firefox-mobile.override {
        wrapFirefox =
            unwrapped: args:
            pkgs.wrapFirefox unwrapped (args // { inherit extraPrefs; });
    };
in
{
    programs.firefox.enable = false;

    home-manager.users.beatlink = {
        home = {
            packages = [ firefox ];

            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".mozilla/firefox"
                    ".config/mozilla/firefox"
                    ".local/share/mozilla/firefox"
                ];
            };
        };
    };
}
