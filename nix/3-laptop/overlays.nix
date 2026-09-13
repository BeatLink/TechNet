# Overlays ###########################################################################################################################################
#
# Upstream test suites that fail on the pinned nixpkgs and have to be skipped. Skipping a package's own tests does not change its runtime behaviour.
#
{
    nixpkgs.overlays = [
        (final: prev: {
            # Reached through qemu-user-static, which boot.binfmt builds statically for the aarch64 emulator.
            libcap_ng =
                if prev.stdenv.hostPlatform.isStatic then
                    prev.libcap_ng.overrideAttrs (_: {
                        doCheck = false; # file_caps_test defines its own fgetxattr/fsetxattr, which musl 1.2.6 now also has in libc.a
                    })
                else
                    prev.libcap_ng;
        })
    ];
}
