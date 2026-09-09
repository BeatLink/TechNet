{
    imports = [
        ./storage-backend.nix
        ./zfs.nix
        ./disko.nix
        ./disko-btrfs-luks.nix
        ./mounts.nix
        ./swap.nix
        ./impermanence.nix
        ./impermanence-btrfs.nix
        ./persistence.nix
        ./directories.nix
        ./temporary-files.nix
        ./tmpfiles-resetup.nix
    ];
}
