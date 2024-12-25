{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        programs.plasma.powerdevil = {
            AC = {
                powerButtonAction = "showLogoutScreen";
                autoSuspend = {
                    action = "sleep";
                    idleTimeout = 900;
                };
                whenSleepingEnter = "standby";
                whenLaptopLidClosed = "sleep"; 
                dimDisplay = {
                    enable = true;
                    idleTimeout = 240;
                };
                turnOffDisplay = {
                    idleTimeout = 300;
                    idleTimeoutWhenLocked = 60;
                };
                inhibitLidActionWhenExternalMonitorConnected = true;
                displayBrightness = 100;
                powerProfile = "performance";
            };
            battery = {
                powerButtonAction = "showLogoutScreen";
                autoSuspend = {
                    action = "sleep";
                    idleTimeout = 120;
                };
                whenSleepingEnter = "standby";
                whenLaptopLidClosed = "sleep";
                dimDisplay = {
                    enable = true;
                    idleTimeout = 60;
                };
            turnOffDisplay = {
                    idleTimeout = 90;
                    idleTimeoutWhenLocked = 30;
                };
                inhibitLidActionWhenExternalMonitorConnected = true;
                displayBrightness = 100;
                powerProfile = "balanced";
            };
            lowBattery = {
                powerButtonAction = "showLogoutScreen";
                autoSuspend = {
                    action = "sleep";
                    idleTimeout = 60;
                };
                whenSleepingEnter = "standby";
                whenLaptopLidClosed = "sleep";
                dimDisplay = {
                    enable = true;
                    idleTimeout = 30;
                };
                turnOffDisplay = {
                    idleTimeout = 45;
                    idleTimeoutWhenLocked = 30;
                };    
                inhibitLidActionWhenExternalMonitorConnected = true;
                displayBrightness = 10;
                powerProfile = "powerSaving";
            };
            general = {
                pausePlayersOnSuspend = true;
            };
            batteryLevels = {
                lowLevel = 25;
                criticalLevel = 2;
                criticalAction =  "shutDown";
            };
        };
    };
}