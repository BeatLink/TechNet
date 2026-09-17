# Claude Code ########################################################################################################################################
#
# The CLI, taken from its own flake rather than from nixpkgs, so the build its CI already published is substituted instead of rebuilt here.
#
# Only the x86_64 hosts gain anything: that flake's CI builds linux-x64 and darwin, so an aarch64 host asking for this package still builds it.
#
{ inputs, ... }:
{
    # The flake's own output, not its overlay: an overlay would re-derive the package against this repo's nixpkgs and miss the cache it exists for.
    nixpkgs.overlays = [
        (_final: prev: {
            claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.claude-code;
        })
    ];

    nix.settings = {
        extra-substituters = [ "https://claude-code.cachix.org" ];
        extra-trusted-public-keys = [
            "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        ];
    };
}
