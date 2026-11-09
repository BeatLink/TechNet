# AWS-LC for Rust packages
#
# nixpkgs' cargo setup hook exports AWS_LC_SYS_USE_SYSTEM=1 for every Rust build, so aws-lc-sys panics in packages
# whose buildInputs do not list aws-lc. withSystem gets nixpkgs' aws-lc; vendored is for aws-lc-sys versions that
# reject it, and builds the copy bundled in the crate. Drop a package once nixpkgs builds it again.
#

{ lib, ... }:
let
    withSystem = [ "newsflash" ];
    vendored = [ "mqttui" ];
in
{
    nixpkgs.overlays = [
        (
            final: prev:
            lib.genAttrs withSystem (
                name:
                prev.${name}.overrideAttrs (old: {
                    buildInputs = (old.buildInputs or [ ]) ++ [ final.aws-lc ];
                })
            )
            // lib.genAttrs vendored (
                name:
                prev.${name}.overrideAttrs (old: {
                    preBuild = (old.preBuild or "") + ''
                        export AWS_LC_SYS_USE_SYSTEM=0
                    '';
                })
            )
        )
    ];
}
