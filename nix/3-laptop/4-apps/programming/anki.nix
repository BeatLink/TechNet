{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ anki ];
                persistence."/Storage/Apps/Programming/Anki" = {
                    directories = [
                        ".local/share/Anki2"
                    ];
                };
            };
        };
}
