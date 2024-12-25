# KWallet #######################################################################################################################
#
# This module disables KWallet since we are using KeePassXC to store all credentials
#
#################################################################################################################################

{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        programs.plasma.configFile = {
            "kwalletrc" =  {
                "Wallet" =  {
                    "Close When Idle" = false;
                    "Close on Screensaver" = false;
                    "Default Wallet" = "kdewallet";
                    "Enabled" = false;
                    "First Use" = false;
                    "Idle Timeout" = 10;
                    "Launch Manager" = true;
                    "Leave Manager Open" = true;
                    "Leave Open" = false;
                    "Prompt on Open" = false;
                    "Use One Wallet" = true;
                };
                "org.freedesktop.secrets"."apiEnabled" = true;
            };
        };
    };
}