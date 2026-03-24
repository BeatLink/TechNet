{ inputs, ... }:
{
    environment.systemPackages = [
        inputs.vantage.packages.x86_64-linux.default
    ];
}
