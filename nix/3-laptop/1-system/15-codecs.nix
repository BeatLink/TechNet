{
    technet.codecs.enable = true;

    home-manager.users.beatlink = {
        home = {
            persistence = {
                "/Storage/Apps/System/Codecs" = {
                    directories = [ ".cache/thumbnails/" ];

                };
            };
        };
    };
}
