# Keyboard diagnostic tools
#
# There are two layers between a keypress and a character, and they fail
# differently -- most of the confusion working out why hyphens did not type came
# from not being able to see which one was at fault. One tool each:
#
#   evtest                      what the kernel driver emits. Shows the raw
#                               scancode and the keycode it was mapped to, so it
#                               answers "did the driver see this key at all".
#                               Needs root and the event device:
#
#                                   sudo evtest /dev/input/event3
#
#                               Pick the device from its own menu, or find it
#                               with `grep -A4 "PinePhone Keyboard" \
#                               /proc/bus/input/devices`.
#
#   xkbcli interactive-wayland  what the application receives, after the layout
#                               has been applied. Prints keycode, keysym and the
#                               resulting UTF-8, which is the one to use for
#                               checking that Pine+9 really produces `minus`.
#                               No root, runs in the session.
#
#   wev                         the Wayland protocol view -- key, modifier and
#                               focus events as the compositor sends them.
#                               Useful when a key produces the right keysym but
#                               the wrong thing still happens, which usually
#                               means a modifier is stuck or a binding is
#                               swallowing it.
#
# The distinction that matters: if a key is missing from evtest, no layout can
# fix it, because the event never reaches userspace. That was true here of
# KEY_MINUS -- it is absent from the driver's capability bitmask entirely, which
# is why the Pine symbols had to come from a level 3 layer on keys that do
# report, rather than from remapping a key that does not.
#
{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
        evtest
        libxkbcommon
        wev
    ];
}
