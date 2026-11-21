{ lib, ... }:
{
    hardware.sensor.hddtemp = {
        enable = true;
        drives = [
            "/dev/disk/by-id/ata-ADATA_SU720_2K442LSNKEEX"
            "/dev/disk/by-id/ata-Dogfish_SSD_64GB_5E56255506071556041"
        ];
        dbEntries = [
            "\"ADATA SU720\" 194 C \"ADATA SU720\""
            "\"Dogfish SSD 64GB\" 190 C \"Dogfish SSD 64GB\""
        ];
    };

    # nixpkgs writes one `echo >> $file` per dbEntry, which trips SC2129, yet its own module also turns the strict check on
    systemd.services.hddtemp.enableStrictShellChecks = lib.mkForce false;
}
