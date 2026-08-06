# Video playback, decoded on the VPU rather than the CPU.
#
# The A64 has a Cedrus video engine and mainline drives it: /dev/video0 is
# `cedrus`, /dev/media0 and /dev/media1 are its Request API nodes, and the
# `dram-ve` clock is wired to 1c0e000.video-codec. None of it was being used --
# every frame was decoded on the same four A53 cores that are already the
# bottleneck on this phone.
#
# It is worth being precise about what this does and does not buy. The Mali-400
# is GLES 2.0, so no UI toolkit here can render on the GPU and nothing in this
# file changes that. The VPU is separate silicon from the GPU, and it is the one
# piece of this SoC that was sitting completely idle.
#
# Cedrus is a *stateless* decoder, so the path is GStreamer's v4l2codecs plugin
# rather than VA-API. There is no VA-API driver for it: Mesa has no Cedrus
# backend, and libva-v4l2-request is an unmaintained out-of-tree shim. The
# plugin registers its elements by probing /dev/media* at load, which is why
# `gst-inspect-1.0 v4l2codecs` reports "0 features" anywhere else -- on a
# machine without the hardware there is nothing to register.
#
# showtime rather than totem or celluloid. It is GTK4/libadwaita and adaptive,
# which matters on a 720x1440 panel; it plays through GStreamer, which is what
# the decoder plugs into; and nixpkgs already bundles gst-plugins-bad in its
# wrapper, so libgstv4l2codecs.so is on its plugin path with nothing to add.
# celluloid is mpv, which does not use GStreamer at all and would need a
# separate V4L2 request path.
{ pkgs, ... }:
{
    # The elements exist but will not be chosen without this.
    #
    # v4l2codecs registers everything at GST_RANK_NONE, deliberately -- upstream
    # will not rank hardware decoders above software ones sight-unseen, because
    # on a lot of devices they are worse. So decodebin keeps picking avdec_*
    # and the VPU stays idle no matter what is installed. Promoting them is the
    # documented way round it.
    #
    # These are the exact names the plugin registered on this phone, read off
    # `gst-inspect-1.0 v4l2codecs` rather than guessed. That distinction cost
    # something: the HEVC element is v4l2slh265dec, not v4l2slhevcdec, and the
    # first version of this file said hevc. A name that matches nothing is
    # silently ignored -- there is no warning and no error -- so H.265 simply
    # went on decoding on the CPU and looked exactly like success.
    #
    # Guessing at names that are not present is therefore worse than useless
    # here, which is why this lists what exists and nothing else. vp9 and av1
    # are deliberately absent: Cedrus on the A64 cannot do either, and carrying
    # them would restore the same false-confidence problem.
    #
    # sessionVariables for the same reason as GSK_RENDERER in
    # 1-system/18-performance.nix: phosh.service runs with PAMName = "login", so
    # pam_env puts this in the session and everything launched from the app grid
    # inherits it. A shell profile variable would reach ssh and nothing tapped.
    environment.sessionVariables.GST_PLUGIN_FEATURE_RANK = builtins.concatStringsSep "," [
        "v4l2slh264dec:MAX"
        "v4l2slh265dec:MAX"
        "v4l2slmpeg2dec:MAX"
        "v4l2slvp8dec:MAX"
        "v4l2slvp8alphadecodebin:MAX"
    ];

    environment.systemPackages = [
        pkgs.showtime

        # v4l2-ctl, for asking the decoder what it supports rather than
        # assuming:
        #
        #   v4l2-ctl -d /dev/video0 --info
        #   v4l2-ctl -d /dev/video0 --list-formats-out
        #
        # The output formats are the codecs it accepts. Worth having on the
        # device because the answer depends on the kernel, not on this file.
        # On the 6.17.5 kernel here that is MPEG-2, H.264, HEVC and VP8.
        #
        # withGUI = false drops qv4l2 and qvidcap, the two Qt front ends this
        # package also ships. Nothing on this phone is Qt, so they pulled the
        # whole qtbase and qt5compat closure onto an SD card to provide a test
        # pattern viewer and a capture window for a decoder with no camera path
        # through it. The flag gates those two binaries only -- v4l2-ctl and the
        # rest of the command line tools are on withUtils and stay.
        (pkgs.v4l-utils.override { withGUI = false; })

        # gst-inspect-1.0 and gst-launch-1.0, for the other half of the
        # question: v4l-utils says what the hardware can do, these say whether
        # GStreamer is actually using it.
        #
        #   BAD=$(ls -d /nix/store/*gst-plugins-bad-*/lib/gstreamer-1.0 | head -1)
        #   GST_PLUGIN_PATH=$BAD gst-inspect-1.0 v4l2codecs
        #   GST_DEBUG=v4l2codecs:5 showtime …   # whether one was chosen
        #
        # The plugin path is not optional in that first command. NixOS wraps
        # each application with its own GST_PLUGIN_SYSTEM_PATH_1_0 and sets none
        # globally, so a bare `gst-inspect-1.0 v4l2codecs` answers "No such
        # element or plugin" on a device where the plugin is present and working
        # -- it is looking in an empty path, not reporting on the hardware.
        #
        # The `.bin` output specifically. nixpkgs splits gstreamer into
        # bin/out/dev/debug and the tools are in `bin`, so the plain package --
        # which is what a closure pulls in for libgstreamer -- has no bin
        # directory at all. That is why gst-inspect-1.0 was missing on this
        # device despite gstreamer plainly being installed.
        #
        # Needed rather than optional because v4l2codecs registers by probing
        # /dev/media* at plugin load. It reports "0 features" on any machine
        # without the hardware, so what it exposes here cannot be checked
        # anywhere but on the phone.
        pkgs.gst_all_1.gstreamer.bin
    ];

    # beatlink is already in `video`, which owns /dev/video0 and /dev/media0, so
    # there is no permission work to do. Noted because it is the first thing to
    # check if decoding silently falls back to software.
}
