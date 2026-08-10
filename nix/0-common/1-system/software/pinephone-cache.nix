# PinePhone Kernel Binary Cache ######################################################################################################################
#
# Opt-in rather than network-wide: elsewhere the substituter is queried for paths it will never hold, and GitHub Pages answers those with HTTP 429.
#

{ config, lib, inputs, ... }:
{
    options.technet.pinephoneCache.enable = lib.mkEnableOption "the PinePhone kernel binary cache";

    # Called rather than imported, because `imports` cannot be placed behind mkIf; this keeps the URL and key from drifting out of the input
    config = lib.mkIf config.technet.pinephoneCache.enable (inputs.pinephone-kernel.nixosModules.binaryCache { });
}
