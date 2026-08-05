# Tangram -- web apps as windows, on WebKitGTK instead of Gecko.
#
# The phone reaches most of its services through a browser (Home Assistant,
# Syncthing's UI, etc), and Firefox is the heaviest thing on the device: a
# cold start was measured at 8.6s idle and 29.8s under Syncthing load, and its
# processes account for most of the CPU whenever it is open.
#
# Tangram pins a site as its own window with its own icon in the app grid, each
# with a separate session, so those become windows rather than tabs in a browser
# that has to be running first. It is small -- a GJS app around a WebKitGTK
# view -- and it is not trying to be a general browser, which is the point.
# Firefox stays installed and stays the browser.
#
# The other reason to have it here is that it is a second rendering engine to
# measure. Firefox falls back to software WebRender on this device because
# WebRender needs GLES 3.0 and the Mali-400 is GLES 2.0, so every page is
# rasterised on the CPU. Whether WebKitGTK does anything better on the same
# hardware is a question this makes answerable rather than one to guess at --
# `gpu-usage` from 1-system/24-gpu-meter.nix is how to tell, by watching whether
# GPU duty moves while a page scrolls.
#
# The pinned tabs are declared by the dconf export in this directory rather than
# set up by hand after every install: which sites, their names, and their user
# agents.
#
# dconf-settings.json carries `"host": "Thor"`, and that tag is load-bearing.
# export-dconf used to dump only on the machine it ran from, so exporting a
# phone-only application from the laptop wrote a zero-byte file and reported
# success -- dconf exits 0 with no output for a path holding no keys, so an
# empty export is indistinguishable from an application that has no settings.
# The tag makes the dump run over ssh against Thor instead. It needs a nixtool
# new enough to understand it; an older one ignores the key and silently empties
# this file on the next export.
#
# The user agent matters more than it looks. WhatsApp Web refuses mobile
# browsers outright -- a UA containing "Mobile" is told to use the phone app
# rather than served the QR pairing page -- and WebKitGTK's own string is not
# one it recognises either. So that tab carries a desktop Chrome UA, which is
# what whatsapp-for-linux uses against the same engine. The cost is that the
# site then renders its desktop layout on a 411x823 logical screen.
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            # Launches from the app grid as "Tangram". The binary is
            # `re.sonny.Tangram`, not `tangram`, which is worth knowing before
            # concluding from a shell that it failed to install.
            packages = [ pkgs.tangram ];

            # The pinned sites and their cookies, logins and local storage. All
            # of it lives under these two directories, and / is rolled back on
            # this host, so without persisting them every web app would need
            # setting up and logging into again on every boot.
            persistence."/Storage/Apps/Core/Tangram" = {
                directories = [
                    ".local/share/re.sonny.Tangram"
                    ".config/re.sonny.Tangram"
                ];
            };
        };
    };
}
