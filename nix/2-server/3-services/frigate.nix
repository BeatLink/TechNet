# frigate.nix - import this in your configuration.nix
# Add to imports: [ ./frigate.nix ]

{ pkgs, ... }:

{
    # Fix for frigate using ffmpeg-headless which is missing some filters
    systemd.services.frigate.path = [ pkgs.ffmpeg-full ];

    # Give frigate access to the camera and GPU
    systemd.services.frigate.serviceConfig = {
        SupplementaryGroups = [
            "video"
            "render"
        ];
    };

    # Make sure iGPU drivers are available for VAAPI decode
    hardware.opengl = {
        enable = true;
        extraPackages = with pkgs; [
            intel-media-driver
            vaapiIntel
            vaapiVdpau
            libvdpau-va-gl
        ];
    };

    services.frigate = {
        enable = true;
        settings = {
            mqtt.enabled = false;
            detectors.cpu1 = {
                type = "cpu";
                num_threads = 3;
            };
            ffmpeg.hwaccel_args = "preset-vaapi";
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
                contour_area = 10;
                improve_contrast = true;
            };
            objects = {
                track = [ "person" ];
                filters.person.min_score = 0.6;
            };
            cameras.apartment = {
                ffmpeg = {
                    inputs = [
                        {
                            path = "/dev/video0";
                            roles = [
                                "detect"
                                "record"
                            ];
                        }
                    ];
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

    nginx-vhosts.frigate = {
        domain = "frigate.heimdall.technet";
        port = 8124;
    };
}
