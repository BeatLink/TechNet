{ lib, pkgs, ... }:
{
    services.go2rtc = {
        enable = true;
        settings = {
            api.listen = ":1984";
            ffmpeg.bin = lib.getExe pkgs.ffmpeg-full;
            log = {
                level = "trace";
            };
            streams = {
                webcam = "exec:${pkgs.ffmpeg}/bin/ffmpeg -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 -i /dev/video0 -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p -an -f rtsp {output}";
            };
        };
    };

    # Setup Users ------------------------------------------------------------------------------------------------------------------------------
    systemd.services.go2rtc.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "go2rtc";
        Group = "go2rtc";

    };
    users = {
        users.go2rtc = {
            isSystemUser = true;
            group = "go2rtc";
            extraGroups = [
                "video"
                "render"
            ];
        };
        groups.go2rtc = { };
    };

    nginx-vhosts."go2rtc" = {
        domain = "go2rtc.heimdall.technet";
        port = 1984;
    };
}
