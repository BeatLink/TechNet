# Package Policy #####################################################################################################################################
#
# Allows unfree packages and drops the NixOS default package set, so every host carries only what it declares.
#

{ lib, ... }:
{
    nixpkgs.config.allowUnfree = true;

    environment.defaultPackages = lib.mkForce [ ];
}
