{ lib, ... }:
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
            "\"Dogfish SSD 64GB\" 190 C \"Dogfish SSD 64GB\""
        ];
    };

    # nixpkgs writes one `echo >> $file` per dbEntry, which trips SC2129, yet its own module also turns the strict check on
    systemd.services.hddtemp.enableStrictShellChecks = lib.mkForce false;
}
