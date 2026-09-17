# Overlay Lint #######################################################################################################################################
#
# Warns during a rebuild when an overlay in this repo builds exactly what nixpkgs already builds, which means the override has been fixed upstream.
#
# Only the top-level package set is compared. An override that exists solely for a variant set -- pkgsStatic, pkgsi686Linux, a python package set --
# is invisible here, and so is any overlay attribute that is not a derivation.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.overlayLint;

    # Nixpkgs with none of this repo's overlays, which is what each overridden package is compared against.
    base = import pkgs.path {
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (pkgs) config;
        overlays = [ ];
    };

    # Every attribute name any overlay defines; applying an overlay forces the names it sets, never their values.
    overlaidNames = lib.unique (
        lib.concatMap (overlay: lib.attrNames (overlay pkgs pkgs)) config.nixpkgs.overlays
    );

    # The derivation an attribute builds, or "" when it is absent, is not a package, or cannot be evaluated here.
    drvPathOf =
        set: name:
        let
            attempt = builtins.tryEval (
                if set ? ${name} && lib.isDerivation set.${name} then set.${name}.drvPath else ""
            );
        in
        if attempt.success then attempt.value else "";

    # An override is a no-op when it lands on the same derivation nixpkgs would have built without it.
    isNoop =
        name:
        let
            overlaid = drvPathOf pkgs name;
        in
        overlaid != "" && overlaid == drvPathOf base name;

    noops = lib.filter isNoop overlaidNames;
in
{
    options.technet.overlayLint.enable =
        lib.mkEnableOption "warning about overlays that no longer change anything"
        // {
            default = true;
        };

    config = lib.mkIf cfg.enable {
        warnings = map (
            name:
            "overlay no-op: pkgs.${name} builds the same derivation as nixpkgs' own, so this repo's override of it can be removed."
        ) noops;
    };
}
