{
    home-manager.users.beatlink = {
        programs.gpaste.enable = true;
        home = {
            persistence."/Storage/Apps/Tools/Calculator" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}
