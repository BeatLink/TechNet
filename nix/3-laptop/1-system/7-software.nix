{
    system.stateVersion = "24.05"; # Did you read the comment?

    # Enable binfmt emulation for cross compilation.
    boot.binfmt.emulatedSystems = [ "aarch64-linux"];

}
