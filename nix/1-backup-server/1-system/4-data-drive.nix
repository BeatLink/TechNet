# Data Drive
#
# Configures settings for mounting the Data Drive for backups
#
# The mount itself comes from the shared module in 0-common, and this host now
# uses the fleet-wide defaults for it: /Storage is beatlink's, like everywhere
# else.
#
# Ownership is scoped to the borg tree instead. Previously /Storage itself was
# borg:borg 0770 and reset recursively (tmpfiles `Z`), which meant every boot
# walked the whole backup tree re-chowning it, and nothing but borg could put
# anything on the drive. The repo directories are what actually need to be
# borg's, so they are declared here and everything above them is left to
# beatlink.
#
# The leaf repo directories are NOT created here: services.borgbackup.repos
# creates each one and chowns it to the repo's user:group in the repo service's
# preStart. What that does not cover is the intermediate directories, which
# `mkdir -p` would leave root-owned -- hence declaring them explicitly.
#

{
    technet.dataDrive.enable = true;

    systemd.tmpfiles.settings."Backup-Drive" = {
        "/Storage/Backups".d = {
            user = "borg";
            group = "borg";
            mode = "0750";
        };
        "/Storage/Backups/Laptop".d = {
            user = "borg";
            group = "borg";
            mode = "0750";
        };
        "/Storage/Backups/Server".d = {
            user = "borg";
            group = "borg";
            mode = "0750";
        };
    };
}
