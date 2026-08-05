{ config, lib, ... }:
let
    plymouth = lib.getExe' config.boot.plymouth.package "plymouth";
in
{
    boot.initrd = {
        allowMissingModules = true;

        unl0kr = {
            enable = true;
            settings = {
                general = {
                    backend = "fbdev";
                    animations = true;
                };
                keyboard = {
                    layout = "us";
                    popovers = true;
                    autohide = false;
                };
                textarea.obscured = true;
                theme = {
                    default = "pmos-dark";
                    alternate = "pmos-light";
                };
            };
        };

        systemd = {
            paths.unl0kr-agent = {
                unitConfig = {
                    ConditionPathExists = "";
                    StartLimitIntervalSec = 0;
                };
                wantedBy = [ "initrd.target" ];
            };

            services.unl0kr-agent = {
                unitConfig = {
                    ConditionPathExists = "";
                    ConditionPathExistsGlob = "/run/systemd/ask-password/ask.*";
                    StartLimitIntervalSec = 0;
                };
                serviceConfig = {
                    ExecStartPre = "-${plymouth} deactivate";
                    ExecStopPost = "-${plymouth} reactivate";
                };
            };
        };
    };
}
