# Vorta
#
# Desktop GUI for BorgBackup. Vorta itself authenticates to the remote repos
# through the desktop ssh-agent, so it needs no key on disk.
#
# The same key is also provisioned here as a sops secret, root-owned, for
# Vigil's manually-triggered backups: Vigil logs into this host as
# `vigil-access` and runs `borg create` under `sudo`, and borg then makes its
# own SSH connection to the repo server. That connection cannot reach the
# desktop agent — Vigil is a system service — so it authenticates with this
# file instead. Same identity the repos already authorize (`odin-borg-key`),
# so Vigil triggers this host's backup rather than performing one under
# credentials of its own.
#
{ inputs, ... }:
{
    sops.secrets.vorta_ssh_key = {
        sopsFile = "${inputs.self}/secrets/3-laptop/vorta.yaml";
        mode = "0400";   # root-only; borg reads it via sudo
    };

    # Passphrase for the encrypted Vorta repos, likewise for Vigil's use: its
    # borg monitors run `cat` on this path to unlock the repo. Vorta itself
    # takes the passphrase from the system keyring, not from here.
    sops.secrets.vorta_backup_passphrase = {
        sopsFile = "${inputs.self}/secrets/3-laptop/vorta.yaml";
        mode = "0400";   # root-only; borg reads it via sudo
    };

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [
                    libnotify
                    vorta
                ];
                persistence."/Storage/Apps/System/Vorta" = {
                    directories = [
                        ".cache/borg"
                        ".cache/Vorta"
                        ".config/borg"
                        ".local/share/Vorta"
                        ".local/state/Vorta"
                    ];
                };
                file = {
                    ".config/autostart/vorta.desktop".source =
                        "${pkgs.vorta}/share/applications/com.borgbase.Vorta.desktop";
                };
            };
        };
}
