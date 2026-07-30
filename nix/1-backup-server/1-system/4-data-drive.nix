# Data Drive
#
# Configures settings for mounting the Data Drive for backups
#
# The mount itself comes from the shared module in 0-common, and this host now
# uses the fleet-wide defaults for it: /Storage is beatlink's, like everywhere
# else.
#
# Ownership is scoped to the borg tree instead. /Storage itself used to be
# borg:borg 0770 reset recursively, which meant nothing but borg could put
# anything on the drive and every boot re-chowned the entire drive. Moving the
# same recursive rule down to /Storage/Backups keeps the self-healing property
# where it is wanted and bounds the walk to the backup tree.
#
# `Z` rather than `d` deliberately: every repo under here is borg:borg (see
# 7-borg.nix), so there is no mixed-ownership subtree for a recursive chown to
# trample, and it repairs anything that ends up misowned -- including the
# intermediate directories `services.borgbackup.repos` creates with `mkdir -p`,
# which it leaves root-owned because it only chowns each repo's leaf.
#
# `d` alongside it because `Z` adjusts but never creates. tmpfiles runs at
# sysinit.target, before the repo services at multi-user.target, so on a fresh
# drive `Z` alone would find nothing to walk and the intermediates would stay
# root-owned until the *next* boot. Creating the parent up front closes that gap.
#

{
    technet.dataDrive.enable = true;

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
