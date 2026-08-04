# Firefox, laptop additions
#
# The package, persistence and the rest are shared in
# 0-common/desktop/4-apps/core/firefox.nix. programs.firefox merges across
# modules, so this only names what Odin has and Thor does not.
#
{ pkgs, ... }:
{
    programs.firefox.nativeMessagingHosts.packages = with pkgs; [
        firefoxpwa
        keepassxc
    ];
}
