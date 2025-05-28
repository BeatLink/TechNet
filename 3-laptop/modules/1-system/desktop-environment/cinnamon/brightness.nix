{
    systemd.services.set-brightness = {
        description = "Set default screen brightness";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = ''
            /run/current-system/sw/bin/bash -c 'echo 255 > /sys/class/backlight/amdgpu_bl1/brightness'
            '';
        };
        # You may need this if writing to /sys requires permissions
        serviceConfig.ExecStartPre = [
            "/run/current-system/sw/bin/chmod u+w /sys/class/backlight/amdgpu_bl1/brightness"
        ];
    };
}