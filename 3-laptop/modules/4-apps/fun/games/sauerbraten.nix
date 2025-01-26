{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;
        home = {
            packages = with pkgs; [ sauerbraten ]; 
            persistence."/Storage/Apps/Fun/Saubraten" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}