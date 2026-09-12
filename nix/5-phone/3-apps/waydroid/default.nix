# Waydroid
#
# Android in a container on this phone's own kernel, and the handover that lets another host draw it instead.
#
{
    imports = [
        ./camera.nix
        ./gnss
        ./remote.nix
        ./session.nix
    ];
}
