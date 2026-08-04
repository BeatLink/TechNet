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
{ lib, pkgs, ... }:
let
    # Paused, not removed.
    #
    # It works -- a window opens by handoff in 2.9s against 8.6s cold -- but it
    # buys that by spending ~400MB and by keeping a browser resident all
    # session, and it treats the symptom. The cause is that nothing on this
    # phone renders on the GPU: GTK4 wants GLES 3.0, Mali-400 tops out at GLES
    # 2.0, so everything falls back to software. Fixing that is worth more than
    # hiding the cost of not having fixed it, so this waits until that is done
    # and the numbers are re-measured.
    #
    # Everything below is left intact, including the phoc hidden-window patch it
    # depends on, so turning it back on is this one line.
    enable = false;

    # Fixed rather than generated per build: it has to be identical in the page
    # and in the environment, and regenerating it on every rebuild would rebuild
    # the page and restart Firefox for no reason.
    warmMarker = "6f8f32ea-159d-4722-a8a4-c1e43da1f8fa";

    # A local file rather than a data: URL. Firefox has refused top-level
    # navigation to data: since 59, so passing one on the command line silently
    # gets nowhere.
    warmPage = pkgs.writeText "firefox-warm.html" ''
        <!doctype html>
        <title>${warmMarker}</title>
        <body style="background:#241f31"></body>
    '';
in
{
    programs.firefox.enable = false;

    # Hide only the warm window: not listed in the overview, and not drawn.
    #
    # Read by the phoc patch in 1-system/14-phosh-bump.nix, which for a matching
    # title skips both exporting the toplevel through
    # zwlr_foreign_toplevel_manager_v1 -- so phosh is never told that window
    # exists and cannot list it -- and rendering it, so it is not what you see
    # when nothing is covering it. Set on phosh.service because phoc runs as its
    # child and inherits it.
    #
    # Matched on title, not app_id. Every Firefox window shares app_id
    # `firefox`, so matching that would hide the browser entirely; the warm
    # window is distinguished instead by the UUID in the page it holds, which
    # nothing else will ever have in its title.
    #
    # The patch re-exports a window whose title stops matching, so if this one
    # is ever navigated away from the marker page it becomes a normal, reachable
    # window rather than being stranded invisible.
    systemd.services.phosh.environment = lib.mkIf enable {
        PHOC_HIDDEN_TITLES = warmMarker;
    };

    home-manager.users.beatlink = {
        home.packages = [ pkgs.firefox-mobile ];

        # Keep one instance running so opening a window is a handoff rather than
        # a start.
        #
        # Firefox hands a second invocation to the instance already holding the
        # profile instead of starting another. Measured on this phone with the
        # system otherwise idle:
        #
        #   cold start                 8.6s
        #   --new-window, warm         2.9s
        #   each further window        ~3s and ~55MB, four totalling 567MB
        #
        # And with Syncthing mid-sync, a cold start was 29.8s. So the warm path
        # is worth 3x idle and 10x under load, which is the difference between
        # irritating and unusable.
        #
        # It costs ~400MB resident. That is the right trade here: memory
        # pressure has measured 0.00 in every sample taken on this device, with
        # 1.2-1.6GB available, so this spends the resource that is spare to buy
        # back the one that is not.
        #
        # This does NOT make the phone faster. It pays the cold cost once, at
        # login, instead of every time you open a window.
        #
        # The window it holds is kept out of the overview by the phoc patch
        # above. It has to exist: the warmth comes from the process holding a
        # live Wayland connection, and any surface it owns is a toplevel.
        # `--headless` was the obvious way to avoid that and is worse than
        # useless -- tested here, the headless instance took 377MB, held the
        # profile lock, and then failed to produce a window at all when asked,
        # timing out after 62s.
        systemd.user.services.firefox-warm = lib.mkIf enable {
            Unit = {
                Description = "Keep Firefox warm so windows open by handoff";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
            };

            Service = {
                # Deliberately late. Boot is already the slowest thing this
                # phone does, and starting a browser into the middle of it moves
                # the cost rather than removing it. The point is to pay it while
                # the session is idle.
                ExecStartPre = "${pkgs.coreutils}/bin/sleep 45";
                ExecStart = "${pkgs.firefox-mobile}/bin/firefox file://${warmPage}";

                # Unkillable from the phone. Swiping it away in the overview
                # closes the window and, being the last one, exits Firefox --
                # which would silently put the cold cost back. Restarting means
                # the only way to stop it is `systemctl --user stop
                # firefox-warm` from a shell.
                #
                # RestartSec is long enough that a genuine crash loop does not
                # thrash a 1.15GHz A53.
                Restart = "always";
                RestartSec = 15;
            };

            Install.WantedBy = [ "graphical-session.target" ];
        };
    };
}
