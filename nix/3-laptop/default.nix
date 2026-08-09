# Module Imports
#

{
    technet.secrets.directory = "3-laptop";

    imports = [
        ../0-common/desktop
        ../0-common/pinephone-cache.nix                                      # Odin builds Thor's closure under binfmt
        ./1-system
        ./4-apps
    ];
}
