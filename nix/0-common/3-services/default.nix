# Services
#
# Services common to every device in the TechNet.
#

{
    imports = [
        ./backup-excludes.nix
        ./borg-compact.nix
        ./ssh.nix
        ./syncthing.nix
        ./x-backups-agent.nix
        ./x-monitor-agent.nix
        ./x-nix-agent.nix
    ];
}
