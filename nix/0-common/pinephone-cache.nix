# PinePhone Kernel Binary Cache
#
# Opt-in, not network-wide: only Thor runs megi's kernel and only Odin builds
# Thor's closure. Elsewhere the substituter is queried for every path it will
# never hold, and GitHub Pages answers those bulk narinfo lookups with HTTP 429.

{ inputs, ... }:
{
    imports = [ inputs.pinephone-kernel.nixosModules.binaryCache ];
}
