{ config, lib, ... }:
let
    plymouth = lib.getExe' config.boot.plymouth.package "plymouth";
in
{
    # The unl0kr module warns unconditionally about Plymouth. The two are reconciled below by handing the
    # framebuffer over for the prompt and taking it back afterwards, so drop that one line and keep the rest.
    options.warnings = lib.mkOption {
        apply = builtins.filter (w: w != "Upstream clearly intends unl0kr to not run with Plymouth. Good luck"); # Matched by text: a reworded warning upstream comes back
    };

    config.boot.initrd = {
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
