# Firefox natively on the phone, alongside the waypipe copy in 3-apps/desktop.
#
# Installed to see what the LUKS root drive bought: a cold start is dominated by faulting the binary and
# its libraries out of /nix, which is the half that got faster. Rendering is not -- toolkit-comparison.nix
# records that the Mali-400 is GLES 2.0 and saturates on fill rate at 720x1440 whatever the engine, which
# is why web apps were moved to waypipe in the first place. Expect it to start well and scroll badly.
#
# The profile already on the card from before that migration is reused rather than started fresh.
#
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.firefox ];

            # All four, because the card carries the pre-waypipe layout and Firefox picks between .mozilla and the XDG paths depending on how it is built
            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".mozilla"
                    ".cache/mozilla"
                    ".config/mozilla"
                    ".local/share/mozilla"
                ];
            };
        };
    };
}
