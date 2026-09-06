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
{ config, ... }:
{
    sops.secrets.vorta_ssh_key = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
        mode = "0400";   # root-only; borg reads it via sudo
    };

    # Passphrase for the encrypted Vorta repos, likewise for Vigil's use: its
    # borg monitors run `cat` on this path to unlock the repo. Vorta itself
    # takes the passphrase from the system keyring, not from here.
    sops.secrets.vorta_backup_passphrase = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
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
            };

            # A unit rather than an autostart .desktop, so borg inherits a cgroup with a ceiling; launched from the session scope it competed with the desktop unthrottled.
            systemd.user.services.vorta = {
                Unit = {
                    Description = "Vorta backup tray";
                    # Qt aborts outright when it starts before Cinnamon imports DISPLAY, so the restart loop is what actually gets it up, as with syncthingtray.
                    StartLimitIntervalSec = 120;
                    StartLimitBurst = 10;
                };
                Service = {
                    ExecStart = "${pkgs.vorta}/bin/vorta";
                    Restart = "on-failure";
                    RestartSec = 5;
                    Nice = 10;
                    CPUQuota = "200%";
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };
        };
}
