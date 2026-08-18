# xed -- a GTK3 text editor for the phone.
#
# The attribute is xed-editor, not xed. `xed` is Intel's X86 Encoder Decoder,
# marked broken on aarch64, and picking it fails evaluation rather than being
# skipped quietly.
#
# It is a GTK3 sample with no GTK4 counterpart on this host, so it says whether
# GTK3 is comfortable here rather than settling the comparison in
# toolkit-comparison.nix -- and it is the only graphical editor on the phone,
# which is reason enough on its own now that the question it was installed for
# has been answered.
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.xed-editor ];

            persistence."/Storage/Apps/System/Xed" = {
                directories = [ ".config/xed" ];
            };
        };
    };
}
