# Dconf
#
# Loads the `.dconf` files that `nixtool run maintenance/export-dconf` writes
# next to each app's `dconf-settings.json`.
#
# `roots` is what makes this shareable. The importer walks the filesystem rather
# than the module graph, so left at the flake root it would load every export in
# the repo onto every host -- and Odin's Cinnamon export covers
# /org/gnome/desktop/, which on Thor would land in the user database and
# override the system defaults set in 6-display.nix. A user value beats a
# profile default, so show-battery-percentage would silently revert.
#
# Scoping to the shared desktop directory plus the host's own keeps each host to
# the exports that belong to it. The host directory comes from
# technet.secrets.directory, which already names it.
#
{ config, inputs, ... }:
let
    flakeRoot = inputs.self.outPath;
in
{
    programs.dconf.enable = true;

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.dconf ];
            dconf.enable = true;
            imports = [
                ./dconf-options.nix
            ];
            dconfImports = {
                enable = true;
                roots = [
                    "${flakeRoot}/nix/0-common/desktop"
                    "${flakeRoot}/nix/${config.technet.secrets.directory}"
                ];
            };
        };
}
