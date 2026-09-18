# Services
#
# Services common to every device in the TechNet.
#

{
    imports = [
        ./borg-compact.nix
        ./ssh.nix
        ./syncthing.nix
        ./vigil-access.nix
        ./vigil-agent.nix
    ];
}
