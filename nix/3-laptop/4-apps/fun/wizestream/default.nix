{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ (pkgs.callPackage ./package.nix { }) ];

            persistence."/Storage/Apps/Fun/WizeStream" = {
                directories = [
                    ".config/wizestream-desktop"
                ];
            };
        };
    };
}
