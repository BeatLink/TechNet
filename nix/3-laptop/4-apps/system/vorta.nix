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
let
    # Borgmatic backs up /Storage/System itself, so every Vorta profile leaves it out of its /Storage source.
    vortaExcludes = {
        inherit (config.backup-excludes) patterns markers;
        raw = [ "pf:/Storage/System" ];
    };
in
{
    sops.secrets.vorta_ssh_key = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
    };

    # Passphrase for the encrypted Vorta repos, likewise for Vigil's use: its
    # borg monitors run `cat` on this path to unlock the repo. Vorta itself
    # takes the passphrase from the system keyring, not from here.
    sops.secrets.vorta_backup_passphrase = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
    };

    # Vigil restores this file from the newest archive and compares it with the live one, so its content must never change.
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
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "display.target" ];
                    After = [ "display.target" ];
                };
                Service = {
                    ExecStart = "${pkgs.vorta}/bin/vorta";
                    Restart = "on-failure";
                    RestartSec = 5;
                    Nice = 10;
                    CPUQuota = "200%";
                };
                Install.WantedBy = [ "display.target" ];
            };

            # Vorta reads a profile's exclusions from its database at the start of each backup, so rewriting them needs no restart of the tray.
            systemd.user.services.vorta-excludes = {
                Unit = {
                    Description = "Write the fleet's backup exclusions into every Vorta profile";
                    Before = [ "vorta.service" ];
                };
                Service = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = "${
                        pkgs.writers.writePython3Bin "vorta-excludes" { flakeIgnore = [ "E501" ]; } ''
                            import json
                            import os
                            import sqlite3
                            import sys

                            DB = os.path.expanduser("~/.local/share/Vorta/settings.db")
                            WANT = json.loads(${builtins.toJSON (builtins.toJSON vortaExcludes)})


                            def main():
                                """Replace every profile's exclusions with the fleet's set, leaving presets off so the list is the whole story."""
                                if not os.path.exists(DB):
                                    print("No Vorta database yet; nothing to do")
                                    return
                                con = sqlite3.connect(DB, timeout=120)
                                with con:
                                    profiles = [row[0] for row in con.execute("SELECT id FROM backupprofilemodel")]
                                    for profile in profiles:
                                        con.execute("DELETE FROM exclusionmodel WHERE profile_id = ?", (profile,))
                                        con.executemany(
                                            "INSERT INTO exclusionmodel (profile_id, name, enabled, source) VALUES (?, ?, 1, 'custom')",
                                            [(profile, pattern) for pattern in WANT["patterns"]],
                                        )
                                        con.execute(
                                            "UPDATE backupprofilemodel SET exclude_patterns = ?, exclude_if_present = ? WHERE id = ?",
                                            ("\n".join(WANT["raw"]), "\n".join("[x] " + m for m in WANT["markers"]), profile),
                                        )
                                print(f"Wrote {len(WANT['patterns'])} patterns to {len(profiles)} profile(s)")


                            if __name__ == "__main__":
                                sys.exit(main())
                        ''
                    }/bin/vorta-excludes";
                };
                Install.WantedBy = [ "default.target" ];
            };
        };
}
