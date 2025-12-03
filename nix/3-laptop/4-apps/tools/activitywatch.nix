{
    home-manager.users.beatlink = {
        services.activitywatch = {
            enable = true;
        };
        home = {
            persistence."/Storage/Apps/Tools/ActivityWatch" = {
                directories = [
                    ".cache/activitywatch"
                    ".config/activitywatch"
                    ".local/share/activitywatch"
                ];
                allowOther = true;
            };
        };
    };
}
