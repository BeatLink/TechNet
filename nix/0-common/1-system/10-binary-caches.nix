# Binary Caches ##########################

{ inputs, ... }:
{
    # Must stay network-wide; Odin builds Thor's closure, so phone-only would never be consulted
    imports = [ inputs.pinephone-kernel.nixosModules.binaryCache ];
}
