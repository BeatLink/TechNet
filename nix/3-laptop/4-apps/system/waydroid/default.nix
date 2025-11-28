{ pkgs, ... }:
{
    virtualisation.waydroid.enable = true;
    environment = {
        systemPackages = with pkgs; [
            weston # Waydroid requirement
        ];
        persistence."/Storage/System/WayDroid/system".directories = [ "/var/lib/waydroid" ];
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
