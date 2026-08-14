# Secrets Paths ######################################################################################################################################

{
    config,
    inputs,
    lib,
    ...
}:
let
    cfg = config.technet.secrets;
in
{
    options.technet.secrets = {
        # Renaming one means updating the matching path_regex in .sops.yaml
        directory = lib.mkOption {
            type = lib.types.str;
            example = "2-server";
            description = "This host's directory under secrets/, relative to the flake root.";
        };

        root = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = "Absolute path to the secrets tree, for the rare module that reads another host's file.";
        };

        path = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = "Absolute path to this host's secrets directory, for use as sopsFile.";
        };

        commonPath = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = "Absolute path to the fleet-wide secrets directory, decrypted by every host.";
        };
    };

    config.technet.secrets = {
        root = "${inputs.self}/secrets";
        path = "${cfg.root}/${cfg.directory}";
        commonPath = "${cfg.root}/0-common";
    };
}
