# Module Imports
#

{
    technet.secrets.directory = "3-laptop";
    technet.pinephoneCache.enable = true; # Odin builds Thor's closure under binfmt

    imports = [
        ../0-common/desktop
        ./1-system
        ./4-apps
    ];
}
