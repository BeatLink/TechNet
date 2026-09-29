# Initrd passphrase prompt ###########################################################################################################################
#
# The LUKS prompt is systemd's plain console agent with buffyboard drawing a touch keyboard under it, so both follow the console when the firmware
# has turned the panel for the keyboard case. unl0kr cannot: buffybox 3.x removed its software rotation.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    plymouth = lib.getExe' config.boot.plymouth.package "plymouth";
    buffyboard = lib.getExe' pkgs.buffybox "buffyboard";
    settings = (pkgs.formats.ini { }).generate "buffyboard.conf" {
        keyboard.haptic_feedback = true;
        theme.default = "pmos-dark";
    };
in
{
    boot.initrd = {
        # The touchscreen, evdev and uinput are built into Thor's kernel, so the generic input module list has nothing to load.
        allowMissingModules = true;

        systemd = {
            contents."/etc/buffyboard.conf".source = settings;
            storePaths = [
                buffyboard
                pkgs.libinput
                pkgs.libinput.out
            ];

            # Both upstream units refuse to run beside Plymouth, so the condition goes and the splash is handed over around the prompt instead.
            paths.systemd-ask-password-console = {
                unitConfig.ConditionPathExists = "";
                wantedBy = [ "sysinit.target" ];
            };
            services.systemd-ask-password-console = {
                unitConfig = {
                    ConditionPathExists = "";
                    StartLimitIntervalSec = 0;
                };
                serviceConfig = {
                    ExecStartPre = "-${plymouth} deactivate";
                    ExecStopPost = "-${plymouth} reactivate";
                };
            };

            # Runs only while a prompt is on the console, and reads its rotation from fbcon on its own.
            services.buffyboard = {
                description = "Touch keyboard for the console passphrase prompt";
                unitConfig = {
                    DefaultDependencies = false;
                    BindsTo = [ "systemd-ask-password-console.service" ];
                    After = [ "systemd-ask-password-console.service" ];
                };
                serviceConfig = {
                    ExecStart = "${buffyboard} --config-override /etc/buffyboard.conf";
                    Restart = "on-failure";
                };
                wantedBy = [ "systemd-ask-password-console.service" ];
            };
        };
    };
}
