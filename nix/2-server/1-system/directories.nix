# Shared Directories ##################################################################################################################################
#
# Directories under /Storage/Files that more than one account writes on this host, and the groups that let them share.
#

{ pkgs, ... }:
{
    # eBooks is written by Syncthing (as beatlink) and calibre-web, each under its own account, so they share it through
    # this group: setgid directories hand it to everything created inside, and each writer's umask keeps group write on.
    users.groups.ebooks = { };
    users.users.beatlink.extraGroups = [ "ebooks" ];

    # Root-owned so the per-service rules below it apply at all: tmpfiles will not act across an ownership change under a non-root parent, and each
    # service directory here belongs to its own account. Services own their own subdirectories, which tmpfiles creates for them.
    systemd.tmpfiles.settings."Storage"."/Storage/Services".d = {
        user = "root";
        group = "root";
        mode = "0755";
    };

    systemd.tmpfiles.settings."Storage"."/Storage/Files/eBooks".d = {
        user = "beatlink";
        group = "ebooks";
        mode = "2775";
    };

    # Applied every activation so anything that slipped in under another group or without group write is folded back in.
    system.activationScripts.ebooksSharedGroup = {
        deps = [ "users" ];
        text = ''
            if [ -d /Storage/Files/eBooks ]; then
                ${pkgs.findutils}/bin/find /Storage/Files/eBooks \! -group ebooks \
                    -exec ${pkgs.coreutils}/bin/chgrp ebooks {} + 2>/dev/null || true
                ${pkgs.findutils}/bin/find /Storage/Files/eBooks -type d \! -perm -g+rwxs \
                    -exec ${pkgs.coreutils}/bin/chmod g+rwxs {} + 2>/dev/null || true
                ${pkgs.findutils}/bin/find /Storage/Files/eBooks -type f \! -perm -g+rw \
                    -exec ${pkgs.coreutils}/bin/chmod g+rw {} + 2>/dev/null || true
            fi
        '';
    };
}
