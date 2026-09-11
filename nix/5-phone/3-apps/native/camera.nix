# Camera
#
# megapixels, which is the only application known to work with this phone's
# cameras. It drives them through libmegapixels, which walks the media graph and
# the sensor subdevices itself rather than going through libcamera, and a
# generic camera app opening /dev/video1 gets a raw sensor stream it cannot
# debayer or scale.
#
# Both sensors work: the rear OV5640 at 2592x1944 and the front GC2145 at
# 1280x720, verified by capturing frames from each.
#
# It needs write access to the flash LED to open either camera at all, which
# nix/5-phone/1-system/camera.nix arranges.
#
# Autofocus on the rear camera is not supported, which is a limitation of the
# driver rather than of this application.
#
{ pkgs, ... }:
{
    environment.systemPackages = [ pkgs.megapixels ];
}
