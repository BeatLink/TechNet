# NixTool
#
# Odin drives every install, so it holds every host's install credentials. Heimdall's and Ragnarok's passphrases are read from the clevis file that
# already owns them; the SSH host keys, and the two passphrases with no other home, live in nixtool.yaml.
#
{ config, ... }:
{
    # Encryption keys ################################################################################################################################
    # Odin is in the recipient list for these two files, so rotating a passphrase stays a single edit to the host's own clevis.yaml.
    sops.secrets.heimdall_zfs_passphrase = {
        key = "zfs_passphrase";
        sopsFile = "${config.technet.secrets.root}/2-server/clevis.yaml";
        owner = "beatlink";
    };
    sops.secrets.ragnarok_zfs_passphrase = {
        key = "zfs_passphrase";
        sopsFile = "${config.technet.secrets.root}/1-backup-server/clevis.yaml";
        owner = "beatlink";
    };

    # NixTool ########################################################################################################################################
    programs.nixtool = {
        enable = true;
        flakePath = "/Storage/Files/Projects/TechNet";
        user = "beatlink";

        hosts = {
            Odin = "odin.technet";
            Heimdall = "heimdall.technet";
            Ragnarok = "ragnarok.technet";
            Thor = "thor.technet";
        };

        hostValueFiles = {
            Heimdall.ENCRYPTION_KEY = config.sops.secrets.heimdall_zfs_passphrase.path;
            Ragnarok.ENCRYPTION_KEY = config.sops.secrets.ragnarok_zfs_passphrase.path;
        };

        sops = {
            enable = true;
            owner = "beatlink";
            sopsFile = "${config.technet.secrets.path}/nixtool.yaml";

            # No SSH_PASSWORD: it is whatever the target's live installer was given that boot, so install-nixos prompts for it
            hostValueSecrets = {
                Odin = {
                    ENCRYPTION_KEY = "odin_encryption_key"; # Odin runs no clevis, so its passphrase has no other file to live in
                    SSH_HOST_KEY = "odin_ssh_host_key";
                    SSH_INITRD_KEY = "odin_ssh_initrd_key";
                };
                Heimdall = {
                    SSH_HOST_KEY = "heimdall_ssh_host_key";
                    SSH_INITRD_KEY = "heimdall_ssh_initrd_key";
                };
                Ragnarok = {
                    SSH_HOST_KEY = "ragnarok_ssh_host_key";
                    SSH_INITRD_KEY = "ragnarok_ssh_initrd_key";
                };
                Thor = {
                    ENCRYPTION_KEY = "thor_encryption_key";
                    SSH_HOST_KEY = "thor_ssh_host_key";
                    SSH_INITRD_KEY = "thor_ssh_initrd_key";
                };
            };
        };
    };
}
