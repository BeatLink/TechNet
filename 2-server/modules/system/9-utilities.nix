{ config, lib, pkgs, modulesPath, ... }: 
{
    hardware.sensor.hddtemp = {
        enable = true;
        drives = [
            "/dev/sda"
            "/dev/sdb"
            "/dev/sdc"
        ];
        dbEntries = [
            "\"TOSHIBA MQ04ABF100\" 194 C \"TOSHIBA MQ04ABF100\""
            "\"WDC WDS120G2G0B-00EPW0\" 194 C \"WDC WDS120G2G0B-00EPW0\""
        ];
    };
}