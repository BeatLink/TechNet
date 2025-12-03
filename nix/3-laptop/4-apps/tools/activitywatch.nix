{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            services.activitywatch = {
                enable = true;
                watchers = {
                    aw-watcher-afk = {
                        package = pkgs.activitywatch;
                        settings = {
                            timeout = 300;
                            poll_time = 2;
                        };
                    };

                    aw-watcher-window = {
                        package = pkgs.activitywatch;
                        settings = {
                            poll_time = 1;
                            exclude_title = true;
                        };
                    };
                };
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
