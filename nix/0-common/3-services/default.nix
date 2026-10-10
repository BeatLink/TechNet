# Services
#
# Services common to every device in the TechNet.
#

{
    imports = [
        ./backup-excludes.nix
        ./borg-compact.nix
        ./remote-deploy.nix
        ./ssh.nix
        ./syncthing.nix
        ./vigil-agent.nix
    ];
}
