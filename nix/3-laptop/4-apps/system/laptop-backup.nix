# Laptop Backup ######################################################################################################################################
#
# What X-Monitor's scheduled backups of /Storage/System need on this host: the repository key and SSH key, and the restore canary. The schedule and
# the backup set live with the monitors in x-monitor.nix.
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
            sops.secrets.borg_repo_encryption_key.sopsFile = "${config.technet.secrets.path}/borgmatic.yaml";
            sops.secrets.borg_repo_ssh_key.sopsFile = "${config.technet.secrets.path}/borgmatic.yaml";
        }

        # Restore Canary #############################################################################################################################
        {
            # X-Monitor restores this file from the newest archive and compares it with the live one, so its content must never change.
            systemd.tmpfiles.settings."Vigil-Canary"."/Storage/System/.vigil-canary".f = {
                user = "root";
                group = "root";
                mode = "0644";
                argument = "Vigil restore canary";
            };
        }
    ];
}
