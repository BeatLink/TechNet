{ pkgs, ... }:
{
    environment.systemPackages = [ pkgs.nemo-with-extensions ];
}
