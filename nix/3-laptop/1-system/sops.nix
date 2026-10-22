# SOPS
#
# sops reads the user's age key from KeePassXC's Secret Service, so no plaintext copy of it exists on disk; the database has to be unlocked to decrypt.
#

{ pkgs, ... }:
let
    ageKeyCommand = pkgs.writeShellScript "sops-age-key" "exec ${pkgs.libsecret}/bin/secret-tool lookup Title 'sops age key'";
in
{
    # Login shells and the desktop session get it from here, user services from environment.d, which systemd --user reads before starting any.
    environment.sessionVariables.SOPS_AGE_KEY_CMD = ageKeyCommand;
    environment.etc."environment.d/60-sops-age-key.conf".text = ''
        SOPS_AGE_KEY_CMD=${ageKeyCommand}
    '';

    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/SOPS" = {
            files = [ ".config/sops/sopsrc" ];
        };
    };
}
