{
    imports = [
        ./1-magicsysrq.nix
        ./2-filesystem-watcher-limit.nix
        ./3-zram.nix
        ./4-earlyoom.nix
        ./5-reboot-on-panic.nix
    ];
}
