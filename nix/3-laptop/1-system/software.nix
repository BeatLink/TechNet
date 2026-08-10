{
    system.stateVersion = "24.05"; # Did you read the comment?

    # Enable binfmt emulation for cross compilation.
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Register a static emulator, which binfmt loads with the F flag: the kernel
    # opens the interpreter once at registration rather than at each exec, so it
    # is still reachable from a chroot. Without this, `nixos-install --root /mnt`
    # cannot run any foreign-architecture builder -- even a writeText -- because
    # /run/binfmt is not visible inside the target root.
    boot.binfmt.preferStaticEmulators = true;

}
