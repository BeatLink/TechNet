# Nemo, laptop additions
#
# The module is shared in 0-common/desktop/4-apps/system/nemo. Both options here
# are additive: extraPackages appends to the shared package list, and bookmarks
# is a types.lines option, which merges definitions by joining them with
# newlines. So this names only what Odin has and the phone does not -- no
# restating the shared set.
#
# mkAfter so these land below the shared entries in the sidebar rather than
# wherever module import order happens to put them.
#
{ lib, pkgs, ... }:
{
    technet.desktop.nemo = {
        extraPackages = with pkgs; [
            nemo-preview
            ffmpeg-full
            imagemagick
            gettext
        ];

        bookmarks = lib.mkAfter ''
            file:///Storage/Files/Projects Projects
            file:///Storage/Files/VMs VMs
            file:///Storage/Files/Backups Backups
        '';
    };
}
