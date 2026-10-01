{ pkgs, ... }:
let
    # GCC 16 makes -Wsfinae-incomplete an error by default, and opencl/source/mem_obj/buffer.h trips it, so the legacy runtime no longer builds.
    # Hydra fails it the same way (https://hydra.nixos.org/build/347345718); drop this once nixpkgs builds it again.
    intel-compute-runtime-legacy1 = pkgs.intel-compute-runtime-legacy1.overrideAttrs (old: {
        env = (old.env or { }) // {
            NIX_CFLAGS_COMPILE = "${old.env.NIX_CFLAGS_COMPILE or ""} -Wno-error=sfinae-incomplete";
        };
    });
in
{
    technet.codecs.enable = true; # Needed for Webcam

    hardware = {
        intel-gpu-tools.enable = true;
        graphics = {
            enable = true;
            extraPackages = [
                # VA-API decode
                pkgs.intel-media-driver
                pkgs.intel-vaapi-driver
                # Compute
                intel-compute-runtime-legacy1
                # VDPAU
                pkgs.libvdpau-va-gl
            ];
        };
    };
}
