{
    programs.gpaste.enable = true;
    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Tools/GPaste" = {
                directories = [
                    ".local/share/gpaste"
                ];
                allowOther = true;
            };
        };
    };
}
