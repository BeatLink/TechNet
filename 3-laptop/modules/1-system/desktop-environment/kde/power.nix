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
                    idleTimeout = 300;
                };
                turnOffDisplay = {
                    idleTimeout = 600;
                    idleTimeoutWhenLocked = 600;
                };
                inhibitLidActionWhenExternalMonitorConnected = true;
                displayBrightness = 100;
                powerProfile = "performance";
            };
            battery = {
                powerButtonAction = "showLogoutScreen";
                autoSuspend = {
                    action = "sleep";
                    idleTimeout = 600;
                };
                whenSleepingEnter = "standby";
                whenLaptopLidClosed = "sleep";
                dimDisplay = {
                    enable = true;
                    idleTimeout = 120;
                };
                turnOffDisplay = {
                    idleTimeout = 240;
                    idleTimeoutWhenLocked = 240;
                };
                inhibitLidActionWhenExternalMonitorConnected = true;
                displayBrightness = 100;
                powerProfile = "balanced";
            };
            lowBattery = {
                powerButtonAction = "showLogoutScreen";
                autoSuspend = {
                    action = "sleep";
                    idleTimeout = 240;
                };
                whenSleepingEnter = "standby";
                whenLaptopLidClosed = "sleep";
                dimDisplay = {
                    enable = true;
                    idleTimeout = 60;
                };
                turnOffDisplay = {
                    idleTimeout = 120;
                    idleTimeoutWhenLocked = 120;
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