# Phosh stack version bump
#
# nixpkgs pins phosh, phoc and stevia at 0.54.0 while upstream is at 0.56.0 --
# and ships xdg-desktop-portal-phosh 0.55.0 in the same closure, so the stack is
# not internally consistent either.
#
# Two things do not work on 0.54.0, and everything underneath both is verified
# working (see TODO.md for the evidence): the screen never rotates although
# iio-sensor-proxy reports orientation live and the mount matrix is applied, and
# the on-screen keyboard never draws although stevia owns sm.puri.OSK0 and
# SetVisible succeeds -- phosh even hides the PIN keypad to make room for a
# surface that never appears.
#
# Both are things phosh asks the compositor to do, and phoc asserts on every
# boot in its layer-shell code:
#
#     phoc_layout_transaction_notify_layer_configured:
#       assertion 'self->pending_layer_configures > 0' failed
#
# A layer surface is exactly what an on-screen keyboard is. That points at the
# compositor rather than at configuration, so the next thing to try is a newer
# one rather than more settings.
#
# Bumped together on purpose. phosh, phoc and stevia are released in lockstep
# from the same project and share protocol expectations between the shell and
# the compositor; moving one alone is how you get a subtler version of the same
# problem.
#
{ ... }:
let
    version = "0.56.0";

    # Each package is re-fetched at the new tag. overrideAttrs cannot reuse the
    # original src, because these expressions build the tag from
    # finalAttrs.version and overriding `version` after the fact does not
    # re-evaluate it.
    phoshSrc =
        pkgs: repo: hash:
        pkgs.fetchFromGitLab {
            domain = "gitlab.gnome.org";
            group = "World";
            owner = "Phosh";
            inherit repo hash;
            tag = "v${version}";
            # Same workaround nixpkgs applies -- NixOS/nixpkgs#485701.
            forceFetchGit = true;
        };

    pkgsFetchWlroots =
        pkgs: rev: hash:
        pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "wlroots";
            repo = "wlroots";
            inherit rev hash;
        };
in
{
    nixpkgs.overlays = [
        (final: prev: {
            wlroots_0_20 = prev.wlroots_0_20.overrideAttrs (_: rec {
                version = "0.20.1";
                src = pkgsFetchWlroots final version "sha256-uuc1dn13FXvFSBvE3+QOi35rLJZmWIUst64oaXGdPFk=";
            });

            # 0.56 needs wlroots 0.20; nixpkgs' 0.54 expression asks for 0.19.
            # Swapped through .override because wlroots_0_19 is a function
            # argument, then src/version through overrideAttrs.
            #
            # phoc patches wlroots with a file out of its *own* source tree --
            # 0001-Revert-layer-shell-error-on-0-dimension-without-anch.patch,
            # described in nixpkgs as removing "a check which crashes Phosh".
            # That is the same subsystem as the assertion this bump is chasing.
            # Because the patch is read from finalAttrs.src, overriding src
            # means the 0.56 version of it is used rather than 0.54's.
            phoc = (prev.phoc.override { wlroots_0_19 = final.wlroots_0_20; }).overrideAttrs (old: {
                inherit version;
                src = phoshSrc final "phoc" "sha256-Xzb7C8ZadjS+fPPYlxoEMGcGkcs5yYzhGZs4Mk2lA70=";

                # Let a window exist without phosh knowing about it.
                #
                # phosh only lists what phoc exports through
                # zwlr_foreign_toplevel_manager_v1, so a toplevel that is never
                # announced cannot appear in the overview. That is the only way
                # to get a hidden window: Wayland has no hide primitive,
                # set_minimized means minimised rather than hidden, and phoc has
                # no window rules.
                #
                # Wanted for the warm Firefox in 3-apps/core/firefox.nix, which
                # has to hold a real window to serve handoffs but should not be
                # something you scroll past.
                #
                # Matches on window *title*, colon-separated tokens in
                # PHOC_HIDDEN_TITLES, substring rather than equality. Title
                # rather than app_id because every Firefox window shares one
                # app_id -- matching on that would hide the browser entirely
                # instead of the one window that should not be there.
                #
                # Empty or unset means stock behaviour, so the patch is inert
                # until asked for.
                #
                # It also tracks changes: a window whose title stops matching is
                # exported again, so a hidden window that gets navigated becomes
                # reachable rather than being stranded invisibly forever.
                #
                # Only the wlr manager is skipped. ext_foreign_toplevel_list_v1
                # is left alone deliberately -- it carries no state and nothing
                # here builds a switcher from it, so leaving it intact keeps
                # `phoc-outputs-states` and lswt working for diagnosis.
                patches = (old.patches or [ ]) ++ [ ./phoc-hide-titles.patch ];
            });

            phosh = prev.phosh.overrideAttrs (_: {
                inherit version;
                src = phoshSrc final "phosh" "sha256-ALpONfAaVP9pBP7qffsHBacH50RHdCKHiX63LaqGMf4=";
            });

            stevia = prev.stevia.overrideAttrs (_: {
                inherit version;
                src = phoshSrc final "stevia" "sha256-Ptlmh6T5VNnP7Atq2lhseop9qEgM7eNcYf/UbA0zbFM=";
            });

            # Was the one straggler: nixpkgs still had 0.54.0 while the shell,
            # the compositor and the keyboard were all on 0.56, which is exactly
            # the split-version state the note at the top of this file warns
            # about. It reads and writes the same sm.puri.phosh and
            # mobi.phosh.shell keys the shell does, so a version behind means it
            # can be editing a schema the running shell no longer has.
            #
            # 0.56.0 is the current release across all four -- checked against
            # the tags on gitlab.gnome.org, not assumed.
            # accountsservice and polkit are both new requirements in 0.56 and
            # absent from nixpkgs' 0.54 expression, which fails at configure:
            #
            #     meson.build:33:22: ERROR: Dependency "accountsservice" not found
            #     meson.build:75:21: ERROR: Dependency "polkit-gobject-1" not found
            #
            # Moving src across a release moves the build requirements with it,
            # and overrideAttrs only carries what is named. These two are the
            # whole difference -- taken by diffing 0.56's meson.build against the
            # inputs nixpkgs already passes, rather than by rebuilding until it
            # stopped complaining.
            phosh-mobile-settings = prev.phosh-mobile-settings.overrideAttrs (old: {
                inherit version;
                src = phoshSrc final "phosh-mobile-settings" "sha256-2Z43syrJbJx1aDFoWthmHdDlOXyWkgPqCuifshEcTSI=";
                buildInputs = (old.buildInputs or [ ]) ++ [
                    final.accountsservice
                    final.polkit
                ];
            });
        })
    ];
}
