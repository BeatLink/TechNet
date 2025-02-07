{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ libreoffice ];
            persistence."/Storage/Apps/Tools/LibreOffice" = {
                directories = [
                    ".config/libreoffice"
                ];
                allowOther = true;
            };
        };
    };
}

