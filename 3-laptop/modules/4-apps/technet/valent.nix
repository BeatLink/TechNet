# Only enable if not using kde

{ pkgs, ... }: 
{
    programs.kdeconnect = {
        enable = true;
        package = pkgs.valent;
    };
    home.persistence."/Storage/Apps/TechNet/Valent" = {
        directories = [
            ".cache/valent"
            ".config/valent"
        ];
        allowOther = true;
    };
}