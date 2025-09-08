# Removes Default Packages ######################################################################################################################
{ lib, ... }:
{
    environment.defaultPackages = lib.mkForce [ ];
}
