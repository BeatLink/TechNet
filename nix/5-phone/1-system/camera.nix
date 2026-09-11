# Camera #############################################################################################################################################
#
# Device access for the two sensors, which on this phone comes down to one permission: the rear flash LED.
#
# libmegapixels opens every device its config names -- media node, sensor subdev, flash -- before it opens the video node, and returns on the first
# failure without closing what it already has. The flash is root-only as the kernel creates it, so megapixels leaks the media fd on that failure,
# retries, is told "Camera already opened", and aborts on an assertion with no camera ever opened. Both cameras are therefore dead until the flash is
# writable, and the one line naming the flash scrolls past as an ordinary warning.
#
# Only the two flash attributes are regrouped. feedbackd's own rule gives brightness, pattern and repeat to the feedbackd group so it can blink this
# same LED for notifications, and taking those would break that.
#
{ pkgs, ... }:
let
    flashAccess = pkgs.writeShellScript "camera-flash-access" ''
        for attr in flash_strobe flash_timeout; do
            [ -e "$1/$attr" ] || continue
            ${pkgs.coreutils}/bin/chgrp video "$1/$attr"
            ${pkgs.coreutils}/bin/chmod g+w "$1/$attr"
        done
    '';
in
{
    services.udev.extraRules = ''
        SUBSYSTEM=="leds", KERNEL=="white:flash", ACTION=="add", RUN+="${flashAccess} /sys%p"
    '';
}
