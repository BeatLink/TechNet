# WebLaunch -- web apps as windows, on the only path that reaches this GPU.
#
# Installed to be tried rather than committed to. The engine question underneath
# it is settled: WebKit under GTK3, asked for GLES 2.0 rather than the desktop
# GL it requests by default, is the one thing measured compositing in hardware
# on this phone -- 0.39 cores against 1.52 on the same animating page, while
# GTK4 and Chromium both demand GLES 3.0 and are refused by lima.
#
# What is not settled is whether that difference is worth anything on the pages
# actually used here, which is what these launchers are for: the same services
# already reachable through Tangram, one tap away on the other
# engine, so the comparison is a matter of using both rather than of reading
# numbers.
#
# Each entry gets its own profile under /Storage, so a login survives the
# rollback of / and so the sites do not share cookies with each other or with
# Tangram's copies of the same sites.
#
# When the trial is over this file either grows into the real declaration --
# Tangram deleted, every service listed here -- or it goes away
# entirely. It should not sit half-adopted.
{ inputs, pkgs, ... }:
let
    weblaunch = inputs.weblaunch.packages.${pkgs.stdenv.hostPlatform.system}.weblaunch;

    services = {
        HomeAssistant = {
            name = "Home Assistant (WebLaunch)";
            url = "https://home-assistant.heimdall.technet";
        };
        Trilium = {
            name = "Trilium (WebLaunch)";
            url = "https://trilium.heimdall.technet";
        };
        Syncthing = {
            name = "Syncthing (WebLaunch)";
            url = "http://localhost:8384";
        };
    };

    launcher =
        id: service:
        pkgs.makeDesktopItem {
            name = "org.weblaunch.WebLaunch.${id}";
            desktopName = service.name;
            # Not lib.escapeShellArg: Exec is not a shell command line, and the
            # desktop entry spec reserves the single quote it would produce.
            exec = builtins.concatStringsSep " " [
                "${weblaunch}/bin/weblaunch"
                "--name"
                ''"${service.name}"''
                "--url"
                ''"${service.url}"''
                "--app-id"
                "org.weblaunch.WebLaunch.${id}"
                "--profile"
                ''"/home/beatlink/.local/share/weblaunch/${id}"''
                # Stated rather than left to the default, because the default is
                # the interesting case here: it also relaxes WebKit's memory
                # pressure thresholds, which on this phone is the difference
                # between a cache that persists and one discarded before it is
                # used again.
                "--cache"
                "on"
            ];
            icon = "web-browser";
            categories = [ "Network" ];
            startupWMClass = "org.weblaunch.WebLaunch.${id}";
        };
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ weblaunch ] ++ pkgs.lib.mapAttrsToList launcher services;

            # One directory for every profile rather than one entry per service,
            # because the set of services being tried will change and the
            # persistence declaration should not have to change with it.
            persistence."/Storage/Apps/Core/WebLaunch" = {
                directories = [ ".local/share/weblaunch" ];
            };
        };
    };
}
