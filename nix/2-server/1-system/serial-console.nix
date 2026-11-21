# Serial Console
#
# A way in without a display or network: a USB serial adapter plugged into this host answers the boot password prompts in the initrd and carries a
# login prompt once booted. Nothing runs while no adapter is attached.
#

{ config, pkgs, ... }:
let
    port = "ttyUSB0";
    baud = "115200";
    initrdSystemd = config.boot.initrd.systemd.package;
in
{
    boot.initrd = {
        availableKernelModules = [
            "ch341"
            "cp210x"
            "ftdi_sio"
            "pl2303"
        ];

        systemd = {
            storePaths = [
                "${pkgs.coreutils}/bin/stty"
                "${initrdSystemd}/bin/systemd-tty-ask-password-agent"
            ];

            services.serial-unlock = {
                description = "Answer boot password prompts on the USB serial adapter";
                bindsTo = [ "dev-${port}.device" ];
                after = [ "dev-${port}.device" ];
                wantedBy = [ "dev-${port}.device" ];
                before = [ "initrd-switch-root.target" ];
                conflicts = [ "initrd-switch-root.target" ];
                unitConfig.DefaultDependencies = "no";
                serviceConfig = {
                    ExecStartPre = "${pkgs.coreutils}/bin/stty -F /dev/${port} ${baud}";
                    ExecStart = "${initrdSystemd}/bin/systemd-tty-ask-password-agent --watch --console=/dev/${port}";
                    Restart = "always";
                    RestartSec = 2;
                };
            };
        };
    };

    services.udev.extraRules = ''
        SUBSYSTEM=="tty", KERNEL=="${port}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="serial-getty@${port}.service"
    '';
}
