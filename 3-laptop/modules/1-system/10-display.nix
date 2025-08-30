{ config, ... }:
{
    hardware = {
        i2c.enable = true;      # Needed for Controlling External Monitor
        graphics = {
            enable = true;
            enable32Bit = true;
        };
        nvidia = {
            modesetting.enable = true;
            powerManagement = {
                enable = true;
                finegrained = true;
            };
            open = true;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.beta;
            prime = {
                amdgpuBusId = "PCI:6:0:0";
                nvidiaBusId = "PCI:1:0:0";
                offload = {
                    enable = true;
                    enableOffloadCmd = true;
                };
            };    
        };
        amdgpu.initrd.enable = true;                           # Enables Graphics in Initrd, Allows External Monitor to load for Password Entry
    };
	services = {
        xserver.videoDrivers = [ "modesetting" "nvidia" ];
        logind = {
            lidSwitch = "ignore";                                   # Override lid switch before login; Fixes system going to sleep on login page
            lidSwitchDocked = "ignore";
        };
    };
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