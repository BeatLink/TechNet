{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ universal-android-debloater ];
                persistence."/Storage/Apps/Tools/Universal-Android-Debloater" = {

                };
            };
        };
}
