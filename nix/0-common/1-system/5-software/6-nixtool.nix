{
    config,
    lib,
    inputs,
    ...
}:
let
    cfg = config.technet.nixtool;

    referencedSecrets = lib.unique (
        lib.concatMap lib.attrValues (lib.attrValues cfg.credentials)
    );
in
{
    imports = [ inputs.nixtool.nixosModules.default ];

    options.technet.nixtool = {
        enable = lib.mkEnableOption "nixtool, with installer credentials sourced from sops";

        sopsFile = lib.mkOption {
            type = lib.types.path;
            description = "sops file holding the installer credentials named in `credentials`.";
        };

        owner = lib.mkOption {
            type = lib.types.str;
            description = ''
                Owner of the decrypted credential files. nixos-anywhere runs
                unprivileged, so these must be readable by the person invoking it
                rather than by root.
            '';
        };

        credentials = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
            default = { };
            example = lib.literalExpression ''
                { Thor = { ENCRYPTION_KEY = "thor_encryption_key"; }; }
            '';
            description = ''
                Per host, a nixtool variable name mapped to the sops secret holding
                its value. This is the only piece nixtool's own module cannot
                express: it takes paths, and this resolves sops secret names into
                the paths sops-nix decrypts them to.
            '';
        };
    };

    config = lib.mkIf cfg.enable {
        sops.secrets = lib.genAttrs referencedSecrets (_: {
            sopsFile = cfg.sopsFile;
            owner = cfg.owner;
            mode = "0400";
        });

        programs.nixtool.hostValueFiles = lib.mapAttrs (
            _: vars: lib.mapAttrs (_: secret: config.sops.secrets.${secret}.path) vars
        ) cfg.credentials;
    };
}
