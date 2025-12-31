# Enable WayDroid
{ pkgs, ... }:
{
    virtualisation.waydroid.enable = true;

    environment = {
        systemPackages = with pkgs; [ weston ];
        persistence."/Storage/System/WayDroid/system" = {
            hideMounts = true;
            directories = [ "/var/lib/waydroid" ];
            files = [ ];
        };
    };
    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/Waydroid/user" = {
            directories = [
                ".local/share/waydroid"
            ];
            allowOther = true;
        };
    };
}
