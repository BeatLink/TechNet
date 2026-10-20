# Android Debug Bridge ###############################################################################################################################
#
# adb for phones on USB and over wireless debugging, with its key kept so a paired phone stays paired.
#

{ lib, pkgs, ... }:
{
    config = lib.mkMerge [
        # Debug Bridge ###############################################################################################################################
        {
            environment.systemPackages = with pkgs; [ android-tools ];

            home-manager.users.beatlink.home.persistence."/Storage/Apps/Tools/Android-Debug-Bridge" = {
                directories = [
                    ".android" # adbkey, which every paired phone trusts
                ];
            };
        }

        # Wireless Debugging Discovery ###############################################################################################################
        {
            # adb finds a phone's wireless debugging port, which changes on every toggle, from mDNS replies sent to this port.
            networking.firewall.allowedUDPPorts = [ 5353 ];
        }
    ];
}
