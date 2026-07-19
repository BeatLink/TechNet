# ESPHome YAML rendering
#
# ESPHome configs are YAML, but they lean on custom tags (`!secret`, `!include`,
# `!lambda`, `!extend`) and on `${...}` substitution placeholders. A stock YAML
# serializer quotes all of those into inert strings, so this module renders via
# `pkgs.formats.yaml` and then unquotes the tag forms afterwards -- the same
# approach `services.home-assistant` uses for its `!include` directives.
#
# In Nix you therefore write secrets and includes as plain strings:
#
#     password = "!secret wifi_password";
#     packages.common = "!include 1-common.yaml";
#
# and multi-line C++ / lambda bodies as ordinary multi-line strings.

{ pkgs, lib }:

let
    yamlFormat = pkgs.formats.yaml { };

    # YAML tags that must survive as bare (unquoted) scalars. A quoted
    # "!secret foo" is read by ESPHome as the literal text, not as a reference,
    # so these have to be unquoted after serialization.
    bareTags = [
        "secret"
        "include"
        "lambda"
        "extend"
        "force"
    ];

    tagAlternation = lib.concatStringsSep "|" bareTags;
in
rec {
    inherit yamlFormat;

    # Render an ESPHome device config attrset to a YAML file.
    #
    # name:   device name, used for the output filename (e.g. "light-bathroom")
    # config: the ESPHome configuration as a Nix attrset
    renderConfig =
        name: config:
        pkgs.runCommand "esphome-${name}.yaml"
            {
                # Serialize with the standard YAML writer first; the sed pass
                # below then restores the bare tag scalars.
                src = yamlFormat.generate "${name}-quoted.yaml" config;
                nativeBuildInputs = [ pkgs.gnused ];
            }
            ''
                sed -E \
                    -e "s/'(!(${tagAlternation})[^']*)'/\1/g" \
                    -e 's/"(!(${tagAlternation})[^"]*)"/\1/g' \
                    "$src" > "$out"
            '';

    # Import a config file. Each is either a plain attrset or a function taking
    # `{ lib, pkgs, ... }` -- the latter for configs that need `lib` helpers.
    loadConfig =
        path:
        let
            v = import path;
        in
        if builtins.isFunction v then v { inherit pkgs lib; } else v;

    # Render every `.nix` file in a directory, yielding `{ "<name>.yaml" = <drv>; }`
    # ready to splice into `environment.etc`.
    renderDir =
        dir:
        lib.mapAttrs' (
            file: _:
            let
                name = lib.removeSuffix ".nix" file;
            in
            lib.nameValuePair "${name}.yaml" (renderConfig name (loadConfig "${dir}/${file}"))
        ) (lib.filterAttrs (file: _: lib.hasSuffix ".nix" file) (builtins.readDir dir));
}
