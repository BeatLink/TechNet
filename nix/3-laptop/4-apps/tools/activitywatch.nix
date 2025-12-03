{
    services.activitywatch = {
        enable = true;
    };
    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/Tools/ActivityWatch" = {
                directories = [
                    ".cache/activitywatch"
                    ".config/activitywatch"
                ];
                allowOther = true;
            };
        };
    };
}
