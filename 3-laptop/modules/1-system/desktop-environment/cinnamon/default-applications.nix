{ config, ... }:
{
    xdg.configFile."mimeapps.list".source = config.lib.file.mkOutOfStoreSymlink "/Storage/Apps/System/DefaultApps/.config/mimeapps.list";
    home.persistence."/Storage/Apps/System/DefaultApps" = {
        files = [
            ".config/X-Cinnamon-xdg-terminals.list"
            ".config/xdg-terminals.list"
        ];
        allowOther = true;
    };
}