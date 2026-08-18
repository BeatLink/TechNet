# Camera
#
# megapixels, which is the only application known to work with this phone's
# cameras. Both the front GC2145 and the rear OV5640 are driven through
# libcamera rather than a plain V4L2 device, and a generic camera app opening
# /dev/video0 gets a raw sensor stream it cannot debayer or scale.
#
# The sensors are already visible without it -- PipeWire enumerates
# `libcamera_input._base_i2c-csi_front-camera_3c` -- so what is missing is
# something that can drive the pipeline rather than any kernel support.
#
# Autofocus on the rear camera is not supported, which is a limitation of the
# driver rather than of this application.
#
{ pkgs, ... }:
{
    environment.systemPackages = [ pkgs.megapixels ];
}
