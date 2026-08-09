# Firefox, phone build
#
{ pkgs, ... }:
let
    extraPrefs = ''
        pref("gfx.webrender.software", true);
        pref("gfx.canvas.accelerated", false);
        pref("webgl.disabled", true);
        pref("gfx.font_rendering.opentype_svg.enabled", false);

        pref("layout.frame_rate", 30);
        pref("general.smoothScroll", false);
        pref("ui.prefersReducedMotion", 1);
        pref("image.animation_mode", "once");

        // Trades Spectre-grade site isolation for two fewer content processes
        pref("fission.autostart", false);
        pref("dom.ipc.processCount", 2);
        pref("dom.ipc.processPrelaunch.enabled", false);
        pref("accessibility.force_disabled", 1);
        pref("browser.tabs.remote.warmup.enabled", false);
        pref("browser.newtab.preload", false);

        pref("browser.tabs.unloadOnLowMemory", true);
        pref("browser.low_commit_space_threshold_percent", 10);
        pref("browser.sessionhistory.max_total_viewers", 0);
        pref("browser.sessionhistory.max_entries", 10);
        pref("browser.sessionstore.max_tabs_undo", 0);
        pref("browser.sessionstore.max_windows_undo", 0);
        pref("image.mem.surfacecache.max_size_kb", 65536);

        pref("browser.cache.disk.enable", false);
        pref("browser.cache.memory.capacity", 32768);
        pref("browser.sessionstore.interval", 300000);

        pref("media.autoplay.default", 5);
        pref("media.autoplay.blocking_policy", 2);
        pref("media.hardware-video-decoding.enabled", false);
        pref("media.cache_size", 32768);
        pref("media.cache_readahead_limit", 30);

        pref("network.prefetch-next", false);
        pref("network.dns.disablePrefetch", true);
        pref("network.http.speculative-parallel-limit", 0);
        pref("browser.urlbar.speculativeConnect.enabled", false);

        pref("browser.ml.enable", false);
        pref("browser.tabs.groups.smart.enabled", false);

        pref("browser.startup.homepage", "about:blank");
        pref("browser.newtabpage.activity-stream.feeds.topsites", false);
        pref("browser.newtabpage.activity-stream.feeds.system.topstories", false);
        pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
        pref("browser.newtabpage.activity-stream.discoverystream.enabled", false);
        pref("browser.newtabpage.activity-stream.showSponsored", false);
        pref("browser.newtabpage.activity-stream.system.showSponsored", false);
        pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

        pref("extensions.update.enabled", false);
        pref("extensions.update.autoUpdateDefault", false);
        pref("browser.search.update", false);

        pref("app.normandy.enabled", false);
        pref("browser.region.update.enabled", false);
        pref("browser.discovery.enabled", false);
        pref("browser.uitour.enabled", false);
        pref("browser.aboutwelcome.enabled", false);
        pref("extensions.getAddons.showPane", false);
        pref("extensions.htmlaboutaddons.recommendations.enabled", false);

        pref("toolkit.telemetry.enabled", false);
        pref("toolkit.telemetry.unified", false);
        pref("toolkit.telemetry.archive.enabled", false);
        pref("datareporting.healthreport.uploadEnabled", false);
        pref("datareporting.policy.dataSubmissionEnabled", false);
        pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
        pref("app.shield.optoutstudies.enabled", false);
    '';

    # Signed AMO build, unmodified -- fetchFirefoxAddon repacks and breaks the signature
    ublock-origin = pkgs.fetchurl {
        # uBlock only moves when this pair is bumped; nothing here self-updates
        url = "https://addons.mozilla.org/firefox/downloads/file/4940584/ublock_origin-1.73.0.xpi";
        hash = "sha256-vMxRp3MVCvSvbh/WLHv963I4t5/yOBuZj6ny449keGo=";
    };

    extraPolicies.ExtensionSettings."uBlock0@raymondhill.net" = {
        installation_mode = "normal_installed";
        install_url = "file://${ublock-origin}";
        updates_disabled = true;
    };

    firefox = pkgs.firefox-mobile.override {
        wrapFirefox =
            unwrapped: args:
            pkgs.wrapFirefox unwrapped (
                args
                // {
                    inherit extraPrefs extraPolicies;
                }
            );
    };
in
{
    programs.firefox.enable = false;

    # sessionVariables so pam_env reaches app-grid launches, as in 25-webkit.nix
    environment.sessionVariables.MOZ_CRASHREPORTER_DISABLE = "1";

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
