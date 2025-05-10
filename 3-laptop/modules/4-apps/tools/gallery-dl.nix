{
    home-manager.users.beatlink = { ... }: {
        programs.gallery-dl = {
            enable = true;
            settings = {
                extractor = {
                    base-directory = "/Storage/Files/Downloads/gallery-dl/";
                    archive = "/Storage/Apps/Tools/Gallery-DL/archives/{category}.sqlite3";
                    cookies = ["firefox"];
                    twitter = {
                        retweets =  true;
                    };
                };
            };
        };
    };
}

