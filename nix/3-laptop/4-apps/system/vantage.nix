{ inputs, pkgs, ... }:
{
    environment.systemPackages = [
        inputs.vantage.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
