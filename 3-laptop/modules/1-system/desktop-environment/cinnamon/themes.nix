{ lib, ... }:

with lib.hm.gvariant;

{
    dconf.settings = {
        "org/cinnamon/theme" = {
            name = "Mint-Y-Dark-Aqua";
        };
    };
}