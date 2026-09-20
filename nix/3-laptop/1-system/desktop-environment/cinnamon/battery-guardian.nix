# Battery Guardian
#
# Counts down over everything on screen when the battery runs low, then suspends unless the charger goes in.
# Comes from its own flake and installs into the system data directory, like the other extensions here.
#
{
    inputs,
    pkgs,
    ...
}:
{
    # Turning it on is org/cinnamon enabled-extensions in the dconf export beside this file
    environment.systemPackages = [
        inputs.battery-guardian.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
