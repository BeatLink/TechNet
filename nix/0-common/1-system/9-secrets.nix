# Secrets Paths
#
# Every host keeps its sops files in one directory under secrets/, and every
# module that needs one spells out the full `${inputs.self}/secrets/<dir>/...`
# path. That directory is a property of the host, not of the module asking for
# it, so it is declared once here and referenced everywhere else.
#
# The directories are named after the device role, not the host -- Ragnarok's
# secrets live in secrets/1-backup-server -- so this cannot be derived from
# config.networking.hostName and is declared per host instead. Each one mirrors
# that host's directory under nix/.
#
# The directory names are load-bearing outside Nix too: .sops.yaml keys its
# creation_rules on these exact path prefixes, so renaming one means updating
# that regex to match.
#

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
        directory = lib.mkOption {
            type = lib.types.str;
            example = "2-server";
            description = ''
                This host's directory under secrets/, relative to the flake root.
                Set once per host; read via technet.secrets.path.
            '';
        };

        path = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = ''
                Absolute path to this host's secrets directory, for use as
                `sopsFile = "${config.technet.secrets.path}/thing.yaml"`.
            '';
        };

        commonPath = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = ''
                Absolute path to the fleet-wide secrets directory, for the handful
                of secrets every host decrypts (the user password, the GitHub token).
            '';
        };
    };

    config.technet.secrets = {
        path = "${inputs.self}/secrets/${cfg.directory}";
        commonPath = "${inputs.self}/secrets/0-common";
    };
}
