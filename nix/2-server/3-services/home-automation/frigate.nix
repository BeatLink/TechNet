{
    inputs,
    pkgs,
    config,
    ...
}:
{
    sops.secrets."frigate_env" = {
        sopsFile = "${inputs.self}/secrets/2-server/frigate.yaml";
        owner = "frigate";
        group = "frigate";
    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Frigate 0750 frigate frigate - -"
        "Z /Storage/Services/Frigate 0750 frigate frigate - -"
    ];

    services = {
        udev.extraRules = ''
            ACTION=="add", SUBSYSTEM=="video4linux", KERNELS=="video0", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/video0 --set-fmt-video=width=1280,height=720,pixelformat=MJPG --set-parm=30"
        '';

        frigate = {
            enable = true;
            hostname = "frigate";
            checkConfig = false;
            settings = {
                database.path = "/Storage/Services/Frigate/data/frigate.db";
                mqtt = {
                    enabled = true;
                    host = "127.0.0.1";
                    user = "frigate";
                    password = "{FRIGATE_MQTT_PASSWORD}";
                    stats_interval = "60";
                };
                detectors.ov = {
                    type = "openvino";
                    device = "GPU";
                };
                model = {
                    width = "300";
                    height = "300";
                    input_tensor = "nhwc";
                    input_pixel_format = "bgr";
                    path = "/Storage/Services/Frigate/ssdlite_mobilenet_v2.xml";
                    labelmap_path = "/Storage/Services/Frigate/coco_91cl_bkgr.txt";
                };
                record = {
                    enabled = true;
                    retain = {
                        days = 0;
                        mode = "motion";
                    };
                    events = {
                        pre_capture = 5;
                        post_capture = 10;
                        retain = {
                            default = 14;
                            mode = "active_objects";
                            objects.person = 14;
                        };
                    };
                };
                motion = {
                    threshold = 25;
                    contour_area = 100;
                    improve_contrast = true;
                };
                objects = {
                    track = [ "person" ];
                    filters.person.min_score = 0.6;
                };
                cameras.apartment = {
                    # Armed/disarmed is driven by Home Assistant over MQTT:
                    #   frigate/apartment/enabled/set  <- "ON" / "OFF"
                    # While OFF, Frigate runs no capture, detection or recording
                    # for this camera (go2rtc keeps the restream up regardless).
                    #
                    # This MUST stay true: Frigate refuses an MQTT "ON" unless the
                    # camera is enabled in the config file ("Camera must be enabled
                    # in the config to be turned on via MQTT"), so setting false
                    # here would make the camera impossible to arm. HA should
                    # publish OFF on startup to reach the disarmed state.
                    enabled = true;
                    ffmpeg = {
                        input_args = [
                            "-f"
                            "v4l2"
                            "-input_format"
                            "mjpeg"
                            "-video_size"
                            "1280x720"
                            "-framerate"
                            "30"
                        ];
                        inputs = [
                            {
                                path = "/dev/video0";
                                roles = [
                                    "detect"
                                    "record"
                                ];
                            }
                        ];
                        hwaccel_args = "preset-vaapi";
                    };
                    detect = {
                        enabled = true;
                        width = 1280;
                        height = 720;
                        fps = 5;
                    };
                    record.enabled = true;
                    snapshots = {
                        enabled = true;
                        timestamp = true;
                        bounding_box = true;
                        retain.default = 14;
                    };

                    # Optional — mask out areas that cause false triggers
                    # e.g. a window with moving trees or a flickering light
                    # motion.mask = [ "0,0,1280,150" ];  # Mask top strip of frame
                };
            };
        };
        nginx.virtualHosts.frigate.listen = [
            {
                addr = "127.0.0.1";
                port = 9310;
            }
        ];
    };

    # Fix for frigate using ffmpeg-headless which is missing some filters
    systemd.services = {
        frigate = {
            path = [ pkgs.ffmpeg-full ];
            serviceConfig = {
                EnvironmentFile = config.sops.secrets."frigate_env".path;
                AmbientCapabilities = "CAP_PERFMON";
                SupplementaryGroups = [
                    "video"
                    "render"
                ];
                # The webcam wedges into a state where it enumerates but only ever
                # delivers truncated frames; a physical replug is what clears it.
                # Unbind/rebind at the usb driver level re-enumerates the device
                # for the same effect. The 5s delay lets the port settle before
                # rebinding; the 2s gives uvcvideo time to reattach (and the udev
                # rule above time to re-apply the MJPG format) before ffmpeg opens
                # the device. The "+" prefix runs this as root, which writing to
                # /sys/bus/usb/drivers requires — the unit itself stays unprivileged.
                ExecStartPre = [
                    "+${pkgs.writeShellScript "frigate-usb-replug" ''
                        usb_id=1-1
                        if [ -e /sys/bus/usb/devices/$usb_id ]; then
                            echo -n "$usb_id" > /sys/bus/usb/drivers/usb/unbind || true
                            sleep 5
                            echo -n "$usb_id" > /sys/bus/usb/drivers/usb/bind || true
                            sleep 2
                        fi
                    ''}"
                ];
            };
        };
    };
    environment.persistence."/Storage/Services/Frigate".directories = [ "/var/lib/frigate" ];
    nginx-vhosts."frigate-web" = {
        domain = "frigate.heimdall.technet";
        port = 9310;
    };
}
