# Services
#
# Services common to every device in the TechNet.
#

{
    imports = [
        ./ssh.nix
        ./syncthing.nix
        ./vigil-access.nix
        ./vigil-agent.nix
    ];
}
