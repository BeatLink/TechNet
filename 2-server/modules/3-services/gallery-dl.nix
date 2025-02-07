{
    home-manager.users.beatlink = { ... }: {
        programs.gallery-dl = {
            enable = true;
            settings = {
                extractor = {
                    base-directory = "/Storage/Files/Downloads/gallery-dl/";
                    archive = "/Storage/Services/Gallery-DL/archives/{category}.sqlite3";
                };
            };
        };
    };
}
