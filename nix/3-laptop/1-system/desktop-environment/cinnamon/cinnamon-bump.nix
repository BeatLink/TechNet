# Cinnamon stack version bump
#
# muffin 6.6.3 advertises zwp_linux_dmabuf_v1 at version 3 and no wl_drm, but Mesa 26 dropped the wl_drm client path
# and learns the render device only from dmabuf feedback (v4), so every GL client on the Wayland session -- Xwayland
# included -- falls back to llvmpipe. 6.7.4 raises META_ZWP_LINUX_DMABUF_V1_VERSION to 4. The whole stack moves with
# it: 6.7 deletes the Meta.Background* headers Cinnamon 6.6 draws the desktop through, and Mint releases these in lockstep.
#
{ ... }:
let
    mintSrc =
        pkgs: repo: tag: hash:
        pkgs.fetchFromGitHub {
            owner = "linuxmint";
            inherit repo hash;
            rev = tag;
        };
in
{
    nixpkgs.overlays = [
        (final: prev: {
            muffin = prev.muffin.overrideAttrs (old: {
                version = "6.7.4-unstable";
                src = mintSrc final "muffin" "6.7.4-unstable" "sha256-saReixkvlFM8VLV7MiOj0oU577d+HYf4ckF4p1DsLo4=";
                # 6.7 installs a udev rule and defaults its directory to systemd's own store path
                mesonFlags = (old.mesonFlags or [ ]) ++ [
                    "-Dudev_dir=${placeholder "out"}/lib/udev"
                ];
            });

            cinnamon = prev.cinnamon.overrideAttrs (old: {
                version = "6.7.4-unstable";
                src = mintSrc final "cinnamon" "6.7.4-unstable" "sha256-g47YAJG/NOK+RzxBdiFKbuxOYe6TD2l0NtjJMVoHelg=";
                # 6.7 adds cinnamon-hover-click (libxdo) and authenticates the Wayland lock screen itself (pam)
                buildInputs = (old.buildInputs or [ ]) ++ [
                    final.xdotool
                    final.pam
                ];
                # nixpkgs cherry-picks the GIR 2.0 fix, which is already in 6.7.4
                patches = prev.lib.filter (
                    p: !prev.lib.hasSuffix "3a2d558aa575f0ea364c5b4e30d2eb3ee604ee58.patch" (toString p)
                ) old.patches;
                # Three of nixpkgs' --replace-fail targets are gone in 6.7: Spices.py lost the double-quoted
                # subprocess.run and msgfmt (now in the new python3/cinnamon module), and the printers applet
                # calls lpstat directly instead of shipping python helpers.
                postPatch =
                    prev.lib.replaceStrings
                        [
                            ''--replace-fail 'subprocess.run(["/usr/bin/''
                            ''--replace-fail "msgfmt"''
                            ''--replace-fail "Util.spawn_async(['python3',"''
                            "./files/usr/bin/cinnamon-session-{cinnamon,cinnamon2d}"
                        ]
                        [
                            ''--replace-quiet 'subprocess.run(["/usr/bin/''
                            ''--replace-quiet "msgfmt"''
                            ''--replace-quiet "Util.spawn_async(['python3',"''
                            "./files/usr/bin/cinnamon-session-cinnamon"
                        ]
                        old.postPatch
                    + ''
                        substituteInPlace ./python3/cinnamon/harvester.py --replace-fail "/usr/bin/msgfmt" "${final.gettext}/bin/msgfmt"
                    '';
                # The printers applet no longer ships the python helpers preFixup chmods and wraps
                preFixup =
                    prev.lib.replaceStrings
                        [
                            "chmod +x $out/share/cinnamon/applets/printers@cinnamon.org/{cancel-print-dialog,lpstat-a}.py"
                            "wrapGApp $out/share/cinnamon/applets/printers@cinnamon.org/cancel-print-dialog.py"
                        ]
                        [ ":" ":" ]
                        old.preFixup;
                # 6.7 drops the 2D session, and the display manager asserts every provided session exists
                passthru = old.passthru // {
                    providedSessions = [
                        "cinnamon"
                        "cinnamon-wayland"
                    ];
                };
            });

            cinnamon-desktop = prev.cinnamon-desktop.overrideAttrs (old: {
                version = "6.7.2-unstable";
                src = mintSrc final "cinnamon-desktop" "6.7.2-unstable" "sha256-DZzLXiPLDN+WWmChvGdndz1QgRnmD9R/yg8d2T9HgFo=";
                # New in 6.7, and overrideAttrs carries only what it is given
                buildInputs = (old.buildInputs or [ ]) ++ [ final.libseccomp ];
            });

            cinnamon-session = prev.cinnamon-session.overrideAttrs (_: {
                version = "6.7.3-unstable";
                src = mintSrc final "cinnamon-session" "6.7.3-unstable" "sha256-RUPxmDzFrZIDuwZ65GkElmb0J4VIGy8JXU/AKY9vHqo=";
            });

            cinnamon-settings-daemon = prev.cinnamon-settings-daemon.overrideAttrs (_: {
                version = "6.7.2-unstable";
                src = mintSrc final "cinnamon-settings-daemon" "6.7.2-unstable" "sha256-NHSqY7RpIJUu6/AHdkZsrxAxLkVBCbQyZlWY6udAyRc=";
            });

            cinnamon-screensaver = prev.cinnamon-screensaver.overrideAttrs (_: {
                version = "6.7.1-unstable";
                src = mintSrc final "cinnamon-screensaver" "6.7.1-unstable" "sha256-l+LYKKTrKPCNa4iZ8XD1oOVndJDYHhcQNy2fMhJI47U=";
            });

            cinnamon-menus = prev.cinnamon-menus.overrideAttrs (_: {
                version = "6.7.0-unstable";
                src = mintSrc final "cinnamon-menus" "6.7.0-unstable" "sha256-BD+2hS5i3fmDja1aSmX1MZiUk3YY5pUxbveq1zwNOds=";
            });

            cinnamon-control-center = prev.cinnamon-control-center.overrideAttrs (old: {
                version = "6.7.2-unstable";
                src = mintSrc final "cinnamon-control-center" "6.7.2-unstable" "sha256-7zVmRIVrOwmU2qAr1QU1pha0Gf2nQjnIiVIK0H+xDNg=";
                # 6.7.2 drops the display panel's desktop file but still symlinks it, and nixpkgs rejects dangling symlinks
                postInstall = (old.postInstall or "") + ''
                    rm -f $out/share/cinnamon-control-center/panels/cinnamon-display-panel.desktop
                '';
            });

            xapp = prev.xapp.overrideAttrs (old: {
                version = "3.3.3-unstable";
                src = mintSrc final "xapp" "3.3.3-unstable" "sha256-sCuyJCFebMBRRMF6zhYWk7Pt0H7diwL92nFoTkA4r8o=";
                # 3.3 puts its status icons on layer-shell under Wayland
                buildInputs = (old.buildInputs or [ ]) ++ [ final.gtk-layer-shell ];
            });

            nemo = prev.nemo.overrideAttrs (_: {
                version = "6.7.4-unstable";
                src = mintSrc final "nemo" "6.7.4-unstable" "sha256-2smKuGWN41yTANSSaXQ/uD46KF5HM2IruJV2mBxk98U=";
            });
        })
    ];
}
