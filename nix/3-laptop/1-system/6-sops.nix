# SOPS
#
# Configures the path to the SSH Host Key for credential decryption
#

{
    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/SOPS" = {
            files = [
                ".config/sops/age/keys.txt"
            ];

        };
    };
}
