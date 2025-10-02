{ config, ... }:
{
    hardware.sensor.iio.enable = true;
    #hardware.firmware = [ config.mobile.device.firmware ];
}
