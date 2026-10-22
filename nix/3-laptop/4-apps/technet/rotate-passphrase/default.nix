# Rotate Passphrase
#
# Installs rotate-passphrase, which changes a host's disk passphrase or a backup set's borg passphrase on the machines and in sops together.
#
{ pkgs, ... }:
{
    environment.systemPackages = [
        (pkgs.writeShellApplication {
            name = "rotate-passphrase";
            runtimeInputs = [
                pkgs.git
                pkgs.libsecret
                pkgs.openssh
                pkgs.python3
                pkgs.sops
            ];
            text = ''exec python3 ${./rotate-passphrase.py} "$@"'';
        })
    ];
}
