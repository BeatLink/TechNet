{pkgs, ...}: {
    systemd.user.services = {
        set-brightness = {
            Unit = {
                Description = "Set default screen brightness";
                After = [ "multi-user.target" ];
            };
            Service = {
                ExecStartPre = [
                    "${pkgs.coreutils-full}/bin/chmod u+w /sys/class/backlight/amdgpu_bl1/brightness"
                ];
                ExecStart = ''
                    ${pkgs.bash}/bin/bash -c 'echo 255 > /sys/class/backlight/amdgpu_bl1/brightness'
                '';
                Type = "oneshot";
            };
            Install = {
                WantedBy = [ "multi-user.target" ];
            };
        };
    };
}