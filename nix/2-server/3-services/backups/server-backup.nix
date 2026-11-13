# Server Backup ######################################################################################################################################
#
# What X-Backups' backups of /Storage/Services need on this host: the repository key and SSH key, the restore canary, and an on-disk repository
# the borg group can read. The schedule and the backup set live in x-backups.nix.
#

{
    lib,
    pkgs,
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
            systemd.tmpfiles.settings."Vigil-Canary"."/Storage/Services/.vigil-canary".f = {
                user = "root";
                group = "root";
                mode = "0644";
                argument = "Vigil restore canary";
            };
        }

        # On-Disk Repository #########################################################################################################################
        {
            systemd.tmpfiles.settings."Borg-Repo"."/Storage/Files/Backups/Heimdall".d = {
                user = "root";
                group = "borg";
                mode = "0750";
            };

            # Touches only files that are wrong: chgrp -R rewrites every inode on ZFS, and on the shingled mirror disk that stalls the pool for minutes.
            systemd.services.borg-repo-group-read = {
                description = "Give the borg group read access to the server's on-disk borg repository";
                wantedBy = [ "multi-user.target" ];
                unitConfig.RequiresMountsFor = [ "/Storage/Files/Backups/Heimdall" ];
                serviceConfig.Type = "oneshot";
                script = ''
                    repo=/Storage/Files/Backups/Heimdall
                    ${pkgs.findutils}/bin/find "$repo" -ignore_readdir_race \! -group borg \
                        -exec ${pkgs.coreutils}/bin/chgrp borg {} + || true
                    ${pkgs.findutils}/bin/find "$repo" -ignore_readdir_race -type d \! -perm -g+rx \
                        -exec ${pkgs.coreutils}/bin/chmod g+rx {} + || true
                    ${pkgs.findutils}/bin/find "$repo" -ignore_readdir_race -type f \! -perm -g+r \
                        -exec ${pkgs.coreutils}/bin/chmod g+r {} + || true
                '';
            };
        }
    ];
}
