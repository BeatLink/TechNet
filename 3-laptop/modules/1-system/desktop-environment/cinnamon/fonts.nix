{ lib, ... }:

with lib.hm.gvariant;

{
    dconf.settings = {
        "org/cinnamon/nemo/desktop" = {
            "fonts" = "Noto Sans 12";
        };
        "org/cinnamon/desktop/interface" = {
            "font-name" = "Noto Sans 12";
        };
        "org/gnome/desktop/interface" = {
            "monospace-font-name" = "Noto Sans Mono 12";
            "document-font-name" = "Noto Sans 12";
            "font-name" = "Noto Sans 12";
        };
        "org/cinnamon/desktop/wm/preferences" = {
            "titlebar-font" = "Noto Sans 12";
        };
        "org/gnome/desktop/wm/preferences" = {
            "titlebar-font" = "Noto Sans 12";
        };
    };
}