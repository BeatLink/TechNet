# Enable ADB
{
    programs.adb.enable = true;

    users.users.beatlink.extraGroups = [ "adbusers" ];

    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/ADB" = {
            directories = [
                ".android"
            ];
            allowOther = true;
        };
    };
}
