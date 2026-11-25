# Account IDs ########################################################################################################################################
#
# Fixed uid and gid numbers for the accounts NixOS would otherwise number itself, matching the owners of this host's data on /Storage, and a check
# that fails the build when an account is left unnumbered, so a fresh root drive can never renumber them.
#

{ config, lib, ... }:
let
    # A user left here after its service is removed fails evaluation as a half-defined account; delete it with the service.
    userIds = {
        beatlink = 1000;
        blockurl = 999;
        borg = 998;
        "calibre-web" = 981;
        esphome = 997;
        freshrss = 996;
        frigate = 995;
        "fwupd-refresh" = 994;
        "mautrix-discord" = 970;
        "mautrix-whatsapp" = 967;
        nscd = 991;
        pihole = 989;
        radicale = 987;
        rtkit = 986;
        sshd = 985;
        "systemd-oom" = 984;
        trilium = 983;
        unbound = 982;
        wpa_supplicant = 972;
        "x-backups-agent" = 974;
        "x-monitor" = 977;
        "x-monitor-access" = 976;
        "x-monitor-agent" = 975;
        "x-nix" = 973;
        "x-nix-agent" = 971;
    };

    groupIds = {
        beatlink = 999;
        blockurl = 998;
        borg = 978;
        "calibre-web" = 977;
        ebooks = 972;
        esphome = 997;
        fail2ban = 971;
        freshrss = 996;
        frigate = 995;
        "fwupd-refresh" = 994;
        "mautrix-discord" = 966;
        "mautrix-whatsapp" = 959;
        nscd = 990;
        pihole = 988;
        polkituser = 987;
        radicale = 985;
        rtkit = 984;
        sshd = 983;
        "systemd-coredump" = 982;
        "systemd-oom" = 981;
        trilium = 980;
        unbound = 979;
        wpa_supplicant = 963;
        "x-backups-agent" = 965;
        "x-monitor" = 970;
        "x-monitor-access" = 969;
        "x-monitor-agent" = 968;
        "x-monitor-credentials" = 967;
        "x-nix" = 964;
        "x-nix-agent" = 962;
    };

    unnumberedUsers = lib.attrNames (lib.filterAttrs (_: user: user.uid == null) config.users.users);
    unnumberedGroups = lib.attrNames (
        lib.filterAttrs (_: group: group.gid == null) config.users.groups
    );
in
{
    config = lib.mkMerge [

        # Pinned IDs #################################################################################################################################
        {
            users.users = lib.mapAttrs (_: uid: { inherit uid; }) userIds;
            users.groups = lib.mapAttrs (_: gid: { inherit gid; }) groupIds;
        }

        # Unnumbered Account Check ###################################################################################################################
        {
            assertions = [
                {
                    assertion = unnumberedUsers == [ ];
                    message = "Users with no fixed uid: ${lib.concatStringsSep ", " unnumberedUsers}; give each one in account-ids.nix.";
                }
                {
                    assertion = unnumberedGroups == [ ];
                    message = "Groups with no fixed gid: ${lib.concatStringsSep ", " unnumberedGroups}; give each one in account-ids.nix.";
                }
            ];
        }
    ];
}
