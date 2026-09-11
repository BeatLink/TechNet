# Waydroid camera ####################################################################################################################################
#
# Hands both of the phone's cameras to Android, which has no driver for either of them.
#
# The image's camera HAL is the external one -- ro.hardware.camera is v4l2 and it is camera-provider-2-7-ext that runs -- so it reads plain V4L2
# capture devices. It cannot use the phone's own /dev/video1: that is the sun6i-csi bridge, whose format list describes the bridge rather than either
# sensor, whose media links have to be set up before a frame appears, and which is one node for two cameras with no way for Android to choose between
# them. So Android gets two v4l2loopback nodes instead, one per sensor, each filled from libcamera.
#
# The format has to be MJPEG. Android's external camera HAL accepts only MJPEG (and Z16 for depth cameras), never raw YUV, which is why every USB
# webcam that works with Android offers an MJPEG mode. Feeding it YUYV looks like it should work and fails silently: the kernel hands the HAL the
# format, the HAL does not recognise the fourcc, drops it without even asking for frame sizes, and reports "0 camera devices". The only trace of it
# is `trimSupportedFormats: input format list is empty` in logcat.
#
# libcamera still does the rest: both sensors emit YUYV themselves -- the OV5640 at any size up to 2592x1944, the GC2145 at 1600x1200 -- so the
# pipeline sets up the media links, picks the sensor's own mode, and only the JPEG encode costs anything.
#
# Waydroid globs /dev/video* when it writes the container's device list and bind mounts every match. It writes that list only from `waydroid init`
# and `waydroid upgrade` though, never at session or container start, so a node that appears afterwards is invisible to Android no matter how often
# the session restarts. After the first switch that adds these, and after any change to which nodes exist, the list has to be rebuilt once:
#
#   sudo waydroid session stop && sudo waydroid upgrade -o
#
# -o keeps the installed images and only regenerates the config. The device numbers below are pinned so that this stays a one-time step rather than
# something that breaks whenever the loopback module happens to load in a different order.
#
{ config, pkgs, lib, ... }:
let
    # The CSI bridge takes one client at a time, so a feeder that streamed continuously would keep megapixels off the camera for as long as Waydroid
    # ran, and would hold a sensor powered up for a phone that is usually doing nothing with it. Each feeder therefore idles holding nothing but its
    # own file descriptor, and starts libcamera only while Android is actually capturing.
    cameras = {
        rear = { device = "/dev/video8"; name = "/base/i2c-csi/rear-camera@4c"; width = 1280; height = 720; label = "AndroidRear"; };
        front = { device = "/dev/video9"; name = "/base/i2c-csi/front-camera@3c"; width = 1600; height = 1200; label = "AndroidFront"; };
    };

    order = [ "rear" "front" ];

    # GStreamer resolves plugins from this one variable, so it has to name every directory at once: setting it to libcamera's alone silently costs
    # you every other element. gstreamer's own plugins, fdsink among them, are in its `out`; plain `pkgs.gst_all_1.gstreamer` is the `bin` output and
    # carries no plugins at all, which shows up only as "no element fdsink" the first time a camera is actually asked for.
    gstPlugins = lib.concatMapStringsSep ":" (p: "${p}/lib/gstreamer-1.0") [
        pkgs.gst_all_1.gstreamer.out
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.libcamera
    ];

    # The loopback device is opened once and held for the life of the service, and that one descriptor does all the work:
    #
    #   - S_FMT on it pins the format. Without an owner v4l2loopback forgets the format on the last close, and Android would find a 640x480 BGRA
    #     device where a camera should be. keep_format is cleared first, because a previous run of this service leaves it set and a set keep_format
    #     makes S_FMT quietly return the old format instead of applying the new one.
    #   - keep_format is set *after* that, because it makes S_FMT return the format the device already has rather than the one asked for. Its real
    #     job is letting Android's STREAMON succeed while no frames are flowing yet; without it the kernel answers EIO and the event below never
    #     arrives, which deadlocks the whole arrangement -- nothing starts the camera because nothing is streaming, and nothing streams because the
    #     camera has not started.
    #   - the same descriptor is handed to gst-launch as its fdsink, so frames go straight from libcamera into the loopback with nothing copying them
    #     in between. It matters that this is an inherited descriptor rather than a second open: keep_format refuses a *new* writer outright.
    #
    # V4L2_EVENT_PRI_CLIENT_USAGE is v4l2loopback's own event and carries a count of streaming readers, so the poll below is woken by Android opening
    # and closing the camera rather than by anything on a timer. Subscribing queues the current state immediately, so a service that starts while
    # Android is already capturing does not wait for the next change.
    feeder =
        pkgs.writers.writePython3Bin "waydroid-camera-feed"
            { flakeIgnore = [ "E501" ]; }
            ''
                import fcntl
                import os
                import select
                import signal
                import struct
                import subprocess
                import sys

                DEVICE, CAMERA, WIDTH, HEIGHT = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])

                V4L2_BUF_TYPE_VIDEO_OUTPUT = 2
                V4L2_FIELD_NONE = 1
                MJPEG = int.from_bytes(b"MJPG", "little")
                # v4l2loopback puts its own events at V4L2_EVENT_PRIVATE_START plus its private offset.
                EVENT_CLIENT_USAGE = 0x08000000 + 0x08E00000 + 1
                CID_KEEP_FORMAT = 0x00980900 | 0xF000


                def ioc(direction, number, size):
                    """Build one ioctl request number the way the kernel's _IOC macros do."""
                    return (direction << 30) | (size << 16) | (0x56 << 8) | number


                # Sizes are of the structs these pass, and a wrong one is a silent ENOTTY rather than a mismatch anyone reports.
                VIDIOC_S_FMT = ioc(3, 5, 208)
                VIDIOC_S_CTRL = ioc(3, 28, 8)
                VIDIOC_SUBSCRIBE_EVENT = ioc(1, 90, 32)
                VIDIOC_DQEVENT = ioc(2, 89, 136)

                fd = os.open(DEVICE, os.O_RDWR)

                # sizeimage is the buffer a compressed frame has to fit in rather than its real length, and bytesperline means nothing for MJPEG.
                pix = struct.pack("13I", WIDTH, HEIGHT, MJPEG, V4L2_FIELD_NONE, 0, WIDTH * HEIGHT, 0, 0, 0, 0, 0, 0, 0)
                fcntl.ioctl(fd, VIDIOC_S_CTRL, bytearray(struct.pack("Ii", CID_KEEP_FORMAT, 0)))
                fcntl.ioctl(fd, VIDIOC_S_FMT, bytearray(struct.pack("II", V4L2_BUF_TYPE_VIDEO_OUTPUT, 0) + pix.ljust(200, b"\0")))
                fcntl.ioctl(fd, VIDIOC_S_CTRL, bytearray(struct.pack("Ii", CID_KEEP_FORMAT, 1)))
                fcntl.ioctl(fd, VIDIOC_SUBSCRIBE_EVENT, bytearray(struct.pack("8I", EVENT_CLIENT_USAGE, 0, 0, 0, 0, 0, 0, 0)))
                print("%s ready at %dx%d" % (DEVICE, WIDTH, HEIGHT), flush=True)

                feed = {"proc": None}


                def start():
                    """Put the sensor on the air, writing into the descriptor this process already owns."""
                    if feed["proc"] is not None:
                        return
                    feed["proc"] = subprocess.Popen(
                        ["gst-launch-1.0", "-q", "libcamerasrc", "camera-name=%s" % CAMERA,
                         "!", "video/x-raw,format=YUY2,width=%d,height=%d" % (WIDTH, HEIGHT),
                         "!", "jpegenc", "quality=80",
                         "!", "fdsink", "fd=%d" % fd],
                        pass_fds=(fd,))
                    print("feeding %s" % CAMERA, flush=True)


                def stop():
                    """Take the sensor back off, which is what frees the CSI bridge for anything else on the phone."""
                    proc = feed["proc"]
                    if proc is None:
                        return
                    feed["proc"] = None
                    proc.terminate()
                    try:
                        proc.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                        proc.wait()
                    print("released %s" % CAMERA, flush=True)


                def shutdown(_signum, _frame):
                    stop()
                    sys.exit(0)


                signal.signal(signal.SIGTERM, shutdown)
                signal.signal(signal.SIGINT, shutdown)

                poller = select.poll()
                poller.register(fd, select.POLLPRI)

                while True:
                    if not poller.poll(None):
                        continue
                    event = bytearray(136)
                    fcntl.ioctl(fd, VIDIOC_DQEVENT, event)
                    if struct.unpack_from("I", event, 0)[0] != EVENT_CLIENT_USAGE:
                        continue
                    # The payload sits at offset 8: the union is 8-byte aligned, so four bytes of padding follow the type.
                    start() if struct.unpack_from("I", event, 8)[0] else stop()
            '';

    service = key: let camera = cameras.${key}; in {
        name = "waydroid-camera-${key}";
        value = {
            description = "Hand the ${key} camera to Android on ${camera.device}";
            wantedBy = [ "multi-user.target" ];
            after = [ "systemd-udev-settle.service" ];
            path = [ pkgs.gst_all_1.gstreamer ];
            environment.GST_PLUGIN_SYSTEM_PATH_1_0 = gstPlugins;
            serviceConfig = {
                ExecStart = "${feeder}/bin/waydroid-camera-feed ${camera.device} ${camera.name} ${toString camera.width} ${toString camera.height}";
                Restart = "always";
                RestartSec = 10;
                SupplementaryGroups = [ "video" ];
                DynamicUser = true;
            };
        };
    };
in
{
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    # exclusive_caps=0 keeps both nodes advertising capture even while no frames are flowing, which is what lets Android list two cameras from the
    # moment it boots rather than only while something is already streaming.
    boot.extraModprobeConfig = ''
        options v4l2loopback devices=2 video_nr=8,9 card_label=${lib.concatMapStringsSep "," (k: cameras.${k}.label) order} exclusive_caps=0,0
    '';

    systemd.services = lib.listToAttrs (map service order);

    # PipeWire lists these two alongside the real cameras, so a browser or a call app on the phone offers "AndroidRear" and "AndroidFront" as well as
    # the sensors themselves. That is cosmetic: it enumerates them but never opens them, so it never takes the format token the feeders hold. The
    # obvious cure is not one -- PIPEWIRE_IGNORE_DEVICE does nothing here (the V4L2 plugin does not implement it), and a wireplumber
    # monitor.v4l2.rules fragment disabling them took every camera node down with it, the libcamera ones included.
}
