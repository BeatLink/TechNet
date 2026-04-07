{
    config,
    lib,
    pkgs,
    ...
}:

let
    inherit (lib)
        mkIf
        mkOption
        types
        ;

    cfg = config.services.esphome;

    esphomeParams =
        if cfg.enableUnixSocket then
            "--socket /run/esphome/esphome.sock"
        else
            "--address ${cfg.address} --port ${toString cfg.port}";
in
{

    options.services.esphome = {
        user = mkOption {
            type = types.str;
            default = "esphome";
            description = "User account under which esphome runs.";
        };

        group = mkOption {
            type = types.str;
            default = "esphome";
            description = "Group under which esphome runs.";
        };

        stateDir = mkOption {
            type = types.path;
            default = "/var/lib/esphome";
            description = "the folder used to store all esphome data.";
        };

    };

    config = mkIf cfg.enable {

        users = {
            users = mkIf (cfg.user == "esphome") {
                esphome = {
                    inherit (cfg) group;
                    isSystemUser = true;
                };
            };
            groups = mkIf (cfg.group == "esphome") { esphome = { }; };
        };

        systemd.tmpfiles.rules = [
            "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
        ];

        systemd.services.esphome = {
            environment = {
                # platformio fails to determine the home directory when using DynamicUser
                PLATFORMIO_CORE_DIR = lib.mkForce "${cfg.stateDir}/.platformio";
                PYTHONPATH = "${pkgs.esphome}/lib/python3.13/site-packages:${pkgs.python3Packages.makePythonPath pkgs.esphome.dependencies}";
            };
            serviceConfig = {
                ExecStart = lib.mkForce "${cfg.package}/bin/esphome dashboard ${esphomeParams} ${cfg.stateDir}";
                User = cfg.user;
                Group = cfg.group;
                DynamicUser = lib.mkForce false;
                WorkingDirectory = lib.mkForce cfg.stateDir;
                StateDirectory = lib.mkForce "";
                StateDirectoryMode = lib.mkForce "";
                ReadWritePaths = [ cfg.stateDir ];
            };
        };
    };
}
