{
    pkgs,
    config,
    ...
}:
{
    sops.secrets."frigate_env" = {
        sopsFile = "${config.technet.secrets.path}/frigate.yaml";
        owner = "frigate";
        group = "frigate";
    };

    systemd.tmpfiles.settings."Frigate" = {
        "/Storage/Services/Frigate" = {
            d = {
                user = "frigate";
                group = "frigate";
                mode = "0750";
            };
            # Group-writable, not 0750: this recurses through the recordings bind mount, so a stricter mode here locks Syncthing out of the folder root.
            Z = {
                user = "frigate";
                group = "frigate";
                mode = "0770";
            };
        };
    };

    # The recordings live under /Storage/Files and are mounted where Frigate expects to write them.
    fileSystems."/var/lib/frigate/recordings" = {
        device = "/Storage/Files/Frigate";
        fsType = "none";
        options = [
            "bind"
            "nofail"
        ];
        depends = [
            "/Storage"
            "/var/lib/frigate"
        ];
    };

    # The recordings tree is 0770 frigate:frigate, so it is unreadable without this.
    users.users.beatlink.extraGroups = [ "frigate" ];

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
                    # here would make the camera impossible to arm. The unit's
                    # prestart parks a retained OFF so it starts disarmed.
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
                        # No hwaccel_args: this camera delivers MJPEG, and VAAPI
                        # is for H.264/H.265 streams. Forcing preset-vaapi on
                        # MJPEG made ffmpeg fail in the hwdownload filter
                        # ("Failed to sync surface", "Failed to download frame:
                        # -5") and crash roughly every two minutes, taking
                        # recording down for the length of each restart. Frigate
                        # flagged it at startup too ("Did not detect hwaccel").
                        # MJPEG is cheap to decode in software, and detection
                        # still runs on the GPU via the openvino detector.
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
            # The disarm prestart publishes to the broker, so it has to be up first.
            after = [ "mosquitto.service" ];
            wants = [ "mosquitto.service" ];
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
                    # Frigate arms every camera from its config at start; this retained OFF is what leaves the apartment camera disarmed until Home Assistant arms it.
                    # Retained rather than plain: nothing is subscribed yet here, and Frigate applies it the moment its MQTT session connects, before the camera process starts.
                    "${pkgs.writeShellScript "frigate-disarm-apartment" ''
                        ${pkgs.mosquitto}/bin/mosquitto_pub \
                            -h 127.0.0.1 -p 1883 \
                            -u frigate -P "$FRIGATE_MQTT_PASSWORD" \
                            -t frigate/apartment/enabled/set -m OFF -r
                    ''}"
                ];
                # Clearing the retained OFF once Frigate has applied it, or every later broker reconnect would silently disarm a camera Home Assistant had armed.
                # -R drops the retained state left by the previous run, so this only ever sees this run's own publishes and cannot clear the command before Frigate reads it.
                ExecStartPost = [
                    "${pkgs.writeShellScript "frigate-clear-disarm-retain" ''
                        if ${pkgs.mosquitto}/bin/mosquitto_sub \
                            -h 127.0.0.1 -p 1883 \
                            -u frigate -P "$FRIGATE_MQTT_PASSWORD" \
                            -t frigate/apartment/enabled/state -R -W 60 | grep -qx OFF
                        then
                            ${pkgs.mosquitto}/bin/mosquitto_pub \
                                -h 127.0.0.1 -p 1883 \
                                -u frigate -P "$FRIGATE_MQTT_PASSWORD" \
                                -t frigate/apartment/enabled/set -n -r
                        else
                            echo "apartment camera never reported disarmed; leaving the retained OFF in place" >&2
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
