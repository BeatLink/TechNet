# Borg Compaction ####################################################################################################################################
#
# Reclaims the space `borg prune` only marks as reusable, weekly, for each repository a host stores itself.
#
# Vorta prunes but never compacts: it decides compaction is due by looking for a recent `--info` subcommand, which is also what its own
# repository-info job records, so the check is always already satisfied. Borgmatic compacts on every run and needs nothing here.
#

{
    config,
    lib,
    pkgs,
    ...
}:

let
    cfg = config.borg-compact;
in
{
    options.borg-compact = lib.mkOption {
        default = { };
        description = "Borg repositories stored on this host, each compacted weekly by a unit named after its attribute.";
        type = lib.types.attrsOf (
            lib.types.submodule {
                options = {
                    path = lib.mkOption {
                        type = lib.types.str;
                        description = "Absolute path to the repository on this host.";
                    };
                    user = lib.mkOption {
                        type = lib.types.str;
                        description = "Account owning the repository, which the compaction runs as so it writes nothing the owner cannot read.";
                    };
                };
            }
        );
    };

    config = lib.mkMerge [

        # Compaction Job #############################################################################################################################
        {
            systemd.services = lib.mapAttrs' (
                name: repo:
                lib.nameValuePair "borg-compact-${name}" {
                    description = "Compact the ${name} borg repository";
                    serviceConfig = {
                        Type = "oneshot";
                        User = repo.user;
                        # Compaction never reads an archive, so the repository passphrase is not needed; the wait lets a running backup finish first.
                        ExecStart = "${pkgs.borgbackup}/bin/borg compact --lock-wait 3600 ${repo.path}";
                        Nice = 19;
                        IOSchedulingClass = "idle";
                    };
                }
            ) cfg;
        }

        # Schedule ###################################################################################################################################
        {
            systemd.timers = lib.mapAttrs' (
                name: _:
                lib.nameValuePair "borg-compact-${name}" {
                    wantedBy = [ "timers.target" ];
                    timerConfig = {
                        # Midweek, because the backup server's integrity checks run on Sundays and hold the same repositories exclusively.
                        OnCalendar = "Wed 04:00";
                        Persistent = true;
                        RandomizedDelaySec = "30m";
                    };
                }
            ) cfg;
        }
    ];
}
