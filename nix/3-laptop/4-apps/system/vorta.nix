# Vorta Repositories #################################################################################################################################
#
# Vorta no longer runs: Odin's /Storage backups move into the borgmatic repositories, and Vorta's repositories stay as read-only history.
# What is left is what reading that history needs: the repositories' SSH key and passphrase, the restore canary, and Vorta's settings.
#
# The key is the identity the repos authorize (`odin-borg-key`), root-owned, so borg can reach them over SSH when it runs under sudo.
#
{ config, ... }:
{
    sops.secrets.vorta_ssh_key = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
    };

    # Passphrase for the encrypted Vorta repos, which the borg monitors read on this host to unlock them.
    sops.secrets.vorta_backup_passphrase = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
    };

    # X-Monitor restores this file from the newest archive and compares it with the live one, so its content must never change.
    systemd.tmpfiles.settings."Vigil-Canary"."/Storage/Files/.vigil-canary".f = {
        user = "root";
        group = "root";
        mode = "0644";
        argument = "Vigil restore canary";
    };

    borg-compact.vorta = {
        path = "/Storage/Files/Backups/Laptop/Vorta";
        user = "beatlink";
    };

    # Vorta's settings database names each profile's sources, excludes and retention, so it stays with the history it describes.
    home-manager.users.beatlink.home.persistence."/Storage/Apps/System/Vorta".directories = [
        ".cache/borg"
        ".cache/Vorta"
        ".config/borg"
        ".local/share/Vorta"
        ".local/state/Vorta"
    ];
}
