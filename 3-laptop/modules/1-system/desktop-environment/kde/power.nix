{ config, lib, pkgs, ... }:
{
    programs.plasma.powerdevil = {
        AC = {
            powerButtonActions = "showLogoutScreen";
            autoSuspend = {
                action = "sleep";
                idleTimeout = 300;
            };
            whenSleepingEnter = "standby";
            whenLaptopLidClosed = "sleep"; 
            dimDisplay = {
                enable = true;
                idleTimeout = 90;
            };
            turnOffDisplay.idleTimeout = 120;
            inhibitLidActionWhenExternalMonitorConnected = true;
            idleTimeoutWhenLocked = 30;
            displayBrightness = 100;
            powerProfile = "performance";
        };
        
        battery = {
            powerButtonActions = "showLogoutScreen";
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
            turnOffDisplay.idleTimeout = 90;
            inhibitLidActionWhenExternalMonitorConnected = true;
            idleTimeoutWhenLocked = 30;
            displayBrightness = 100;
            powerProfile = "balanced";
        };
        lowBattery = {
            powerButtonActions = "showLogoutScreen";
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
            turnOffDisplay.idleTimeout = 45;
            inhibitLidActionWhenExternalMonitorConnected = true;
            idleTimeoutWhenLocked = 30;
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
}