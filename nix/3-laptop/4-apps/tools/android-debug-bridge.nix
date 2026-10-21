# Android Debug Bridge ###############################################################################################################################
#
# adb for phones on USB and over wireless debugging, signing in with a key from sops that every paired phone already trusts.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    adbKeySecret = config.sops.secrets.adb_private_key;
in
{
    config = lib.mkMerge [
        # Debug Bridge ###############################################################################################################################
        {
            environment.systemPackages = with pkgs; [ android-tools ];

            home-manager.users.beatlink.home.persistence."/Storage/Apps/Tools/Android-Debug-Bridge" = {
                directories = [
                    ".android" # adb_known_hosts and the server's state
                ];
            };
        }

        # Debug Bridge Key ###########################################################################################################################
        {
            sops.secrets.adb_private_key = {
                sopsFile = "${config.technet.secrets.path}/android-debug-bridge.yaml";
                owner = "beatlink";
            };

            home-manager.users.beatlink =
                { config, ... }:
                {
                    # adb makes a new, untrusted key whenever ~/.android/adbkey is missing, so the link must always be there.
                    home.file.".android/adbkey".source = config.lib.file.mkOutOfStoreSymlink adbKeySecret.path;
                };
        }
    ];
}
