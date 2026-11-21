# Presence -- a Home Assistant package that sees Thor and the PineTime over Heimdall's Bluetooth radio.
#
# Thor only answers while its Bluetooth is switched on, and the PineTime stops advertising while a phone holds its connection.
{ pkgs }:
let
    thorAddress = "00:E0:4C:23:99:87";
in
{
    command_line = [
        {
            binary_sensor = {
                name = "Thor Nearby";
                unique_id = "thor_bluetooth_nearby";
                command = "${pkgs.bluez}/bin/l2ping -c 1 -t 5 ${thorAddress} > /dev/null 2>&1 && echo ON || echo OFF";
                device_class = "presence";
                scan_interval = 60;
            };
        }
    ];

    device_tracker = [
        {
            platform = "bluetooth_le_tracker";
            # known_devices.yaml is a read-only store file, so new devices could not be written to it
            track_new_devices = false;
        }
    ];
}
