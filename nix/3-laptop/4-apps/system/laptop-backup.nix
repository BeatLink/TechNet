# Laptop Backup ######################################################################################################################################
#
# What X-Backups' backups of /Storage need on this host: the repository key and SSH key, and the restore canary. The schedule and the backup set
# live in Heimdall's x-backups.nix.
#

{
    lib,
    config,
    ...
}:
{
    config = lib.mkMerge [

        # Repository Credentials #####################################################################################################################
        {
            sops.secrets.borg_repo_encryption_key.sopsFile = "${config.technet.secrets.path}/borg.yaml";
            sops.secrets.borg_repo_ssh_key.sopsFile = "${config.technet.secrets.path}/borg.yaml";
        }

        # Restore Canary #############################################################################################################################
        {
            # X-Backups restores this file from the newest archive and compares it with the live one, so its content must never change.
            systemd.tmpfiles.settings."Vigil-Canary"."/Storage/System/.vigil-canary".f = {
                user = "root";
                group = "root";
                mode = "0644";
                argument = "Vigil restore canary";
            };
        }
    ];
}
