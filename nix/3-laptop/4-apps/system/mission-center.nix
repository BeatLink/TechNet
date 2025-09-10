#stacer
#gnome system monitor

{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ mission-center ];
                persistence."/Storage/Apps/System/Mission-Center" = {
                    directories = [
                        ".config/MissionCenter"
                        ".local/share/MissionCenter"
                    ];
                    allowOther = true;
                };
            };
        };
}
