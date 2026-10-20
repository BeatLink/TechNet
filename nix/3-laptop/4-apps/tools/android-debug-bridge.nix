# Android Debug Bridge ###############################################################################################################################
#
# adb for phones on USB and over wireless debugging, with its key kept so a paired phone stays paired.
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ android-tools ];

    home-manager.users.beatlink.home.persistence."/Storage/Apps/Tools/Android-Debug-Bridge" = {
        directories = [
            ".android" # adbkey, which every paired phone trusts
        ];
    };
}
