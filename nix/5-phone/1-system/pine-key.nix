# Pine key ###########################################################################################################################################
#
# The Pine key is the case's level 3 switch for the blue symbols -- see ./keyboard-layout -- which leaves a bare tap of it doing nothing at all.
#
# A tap now toggles phosh's overview, the same thing the home bar does, while holding it still reaches every blue symbol.
#
{ ... }:
{
    # Tap and hold ###################################################################################################################################

    # The hold half is keyd's built-in meta layer, so xkb still sees LEFTMETA and level3(lwin_switch) still selects the blue symbols.
    # overloadt2 rather than overload, for the same reason as FN in ./fn-lock.nix: holding Pine alone must commit to the hold rather than count as a tap.
    services.keyd.keyboards.pinephone.settings.main.leftmeta = "overloadt2(meta, homepage, 200)";

    # Overview binding ###############################################################################################################################

    # XF86HomePage rather than a Super chord, because lwin_switch spends LEFTMETA on the level 3 switch and this keyboard can emit no Super at all.
    programs.dconf.profiles.user.databases = [
        {
            settings."org/gnome/shell/keybindings".toggle-overview = [ "XF86HomePage" ];
        }
    ];
}
