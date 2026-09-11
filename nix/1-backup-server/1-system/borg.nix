# Borg Repositories ##################################################################################################################################
#
# The receiving end of the network's backups: one repository per source host, each authorised only for that host's own borg key.
#

{
    lib,
    pkgs,
    config,
    ...
}:
let
    serverRepo = "/Storage/Backups/Server/Borgmatic";

    # Builds a oneshot unit that verifies the server repo on this host, so a slow check never blocks Heimdall's backup run.
    mkCheck = extraArgs: {
        description = "Check the server's borg repository";
        serviceConfig = {
            Type = "oneshot";
            User = "borg";
            Group = "borg";
            StateDirectory = "borg-check";
            Nice = 19;
            IOSchedulingClass = "idle";
            IOSchedulingPriority = 7;
            IOWeight = 10;
            CPUWeight = 10;
            ExecStart = lib.concatStringsSep " " (
                [
                    "${pkgs.borgbackup}/bin/borg"
                    "check"
                    "--lock-wait"
                    "900"
                ]
                ++ extraArgs
                ++ [ serverRepo ]
            );
        };
        environment = {
            BORG_PASSCOMMAND = "cat ${config.sops.secrets.borg_repo_encryption_key.path}";
            BORG_BASE_DIR = "/var/lib/borg-check"; # The borg user's home is /var/empty, so borg has nowhere to put its cache without this
            BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes"; # Heimdall created the repo through an ssh:// URL; reading it by local path counts as relocated
        };
    };
in
{
    config = lib.mkMerge [

        # Backup Tree Ownership ######################################################################################################################
        {
            systemd.tmpfiles.settings."Backup-Drive"."/Storage/Backups" = {
                d = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
                Z = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
            };
        }

        # Repositories ###############################################################################################################################
        {
            services.borgbackup.repos = {
                laptop-vorta = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERN9fyw16t2LvfrrZdO1CpY5ZWEolg2bY1ZF4WF2SU odin-borg-key"
                    ];
                    path = "/Storage/Backups/Laptop/Vorta";
                };
                laptop-borgmatic = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
                    ];
                    path = "/Storage/Backups/Laptop/Borgmatic";
                };
                server = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdCCw57/UyY1YBTjif2/bMsVDSOVurJ946fKMsBOyoI heimdall-borg-key"
                    ];
                    path = serverRepo;
                };
            };
        }

        # Repository Integrity Checks ################################################################################################################
        # A checksum mismatch inside a segment is invisible to btrfs, which sees only the bytes it was handed, so borg has to look for itself.
        # Heimdall checks this repo too; these run on Sundays to stay clear of its weekday schedule, since a check locks the repo exclusively.
        {
            sops.secrets.borg_repo_encryption_key = {
                sopsFile = "${config.technet.secrets.path}/borg-check.yaml";
                owner = "borg";
            };

            systemd.services.borg-check = mkCheck [ ];
            systemd.timers.borg-check = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "Sun *-*-* 02:00:00";
                    RandomizedDelaySec = "30m";
                    Persistent = true;
                };
            };

            # --verify-data re-reads and re-hashes every chunk, which is far too slow on this board to run weekly.
            systemd.services.borg-check-data = mkCheck [ "--verify-data" ];
            systemd.timers.borg-check-data = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "Sun *-*-01..07 03:00:00";
                    RandomizedDelaySec = "30m";
                    Persistent = true;
                };
            };
        }
    ];
}
