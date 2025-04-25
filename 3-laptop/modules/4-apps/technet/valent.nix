# Only enable if not using kde

{ pkgs, ... }: 
{
    programs.kdeconnect = {
        enable = true;
        package = pkgs.valent;
    };
}