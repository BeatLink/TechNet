{ lib, ... }:
{
    hardware.sensor.hddtemp = {
        enable = true;
        drives = [
            "/dev/disk/by-id/ata-TOSHIBA_MQ04ABF100_18BPSDNPS"
            "/dev/disk/by-id/ata-ADATA_SU720_2K442LSNKEEX"
            "/dev/disk/by-id/ata-Dogfish_SSD_64GB_5E56255506071556041"
        ];
        dbEntries = [
            "\"TOSHIBA MQ04ABF100\" 194 C \"TOSHIBA MQ04ABF100\""
            "\"ADATA SU720\" 194 C \"ADATA SU720\""
            "\"Dogfish SSD 64GB\" 190 C \"Dogfish SSD 64GB\""
        ];
    };

    # The Toshiba is the only spinning disk here and is specified to 60C, so it warns far below the flash ceiling the shared default sets; smartd drops
    # the scanned duplicate in favour of this entry, and a replacement drive falls back to that default rather than going unwatched.
    services.smartd.devices = [
        {
            device = "/dev/disk/by-id/ata-TOSHIBA_MQ04ABF100_18BPSDNPS";
            options = "-W 0,55,58";
        }
    ];

    # nixpkgs writes one `echo >> $file` per dbEntry, which trips SC2129, yet its own module also turns the strict check on
    systemd.services.hddtemp.enableStrictShellChecks = lib.mkForce false;
}
