{
    home-manager.users.beatlink = { ... }: {
        programs.gallery-dl = {
            enable = true;
        };
        home.persistence."/Storage/Apps/Tools/Gallery-DL" = {
            directories = [
                ".config/gallery-dl"
            ];
            allowOther = true;
        };
    };
}

