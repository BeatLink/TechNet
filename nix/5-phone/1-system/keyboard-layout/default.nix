# Keyboard layout
#
# See ./pinephone for the detail. In short: the keycaps label the number row
# twice, blue for Pine and orange for FN. The driver implements the orange half
# correctly -- FN gives F1-F10, Insert, Home, End and the arrows -- but maps
# Pine to a plain KEY_LEFTMETA with no layer behind it, so every blue symbol is
# unreachable. KEY_MINUS is not even in the device's capability bitmask.
#
# Making Pine the xkb level 3 switch puts the blue symbols back without touching
# the kernel or the FN layer. Patching the driver's keymap was the alternative
# and is worse: its single FN layer cannot hold both symbols and function keys,
# so it would have meant giving up F-keys the hardware labels correctly.
#
# Odin is untouched: it has a normal keyboard and gets the plain `us` layout
# from 0-common/1-system/locale/keyboard.nix.
#
{ lib, ... }:
{
    imports = [
        ./tools.nix
    ];

    services.xserver.xkb.extraLayouts.pinephone = {
        description = "PinePhone keyboard case, Pine layer symbols";
        languages = [ "eng" ];
        symbolsFile = ./pinephone;
    };

    # mkForce because 0-common sets `us` plainly for the whole network.
    services.xserver.xkb.layout = lib.mkForce "pinephone";

    # phosh reads its layout from dconf, not services.xserver; both must agree
    # Exported to ../dconf/shell as org.gnome.desktop.input-sources.dconf
}
