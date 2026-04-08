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

    services = {
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
                    ffmpeg = {
                        inputs = [
                            {
                                path = "rtsp://127.0.0.1:8554/webcam";
                                roles = [
                                    "detect"
                                    "record"
                                ];
                            }
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
            };
        };

    };
    environment.persistence."/Storage/Services/Frigate".directories = [ "/var/lib/frigate" ];
    nginx-vhosts."frigate-web" = {
        domain = "frigate.heimdall.technet";
        port = 9310;
    };
}
