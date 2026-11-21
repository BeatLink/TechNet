{ lib, ... }:
{
    hardware.sensor.hddtemp = {
        enable = true;
        drives = [
            "/dev/disk/by-id/ata-ADATA_SU720_2K442LSNKEEX"
        ];
        dbEntries = [
            "\"ADATA SU720\" 194 C \"ADATA SU720\""
        ];
    };

    # nixpkgs writes one `echo >> $file` per dbEntry, which trips SC2129, yet its own module also turns the strict check on
    systemd.services.hddtemp.enableStrictShellChecks = lib.mkForce false;
}
