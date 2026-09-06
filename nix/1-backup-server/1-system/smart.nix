# SMART Monitoring ###################################################################################################################################
#
# Names both USB disks explicitly, because smartd's own device scan misreads the JMicron bridge and leaves the data drive unmonitored.
#

{
    services.smartd = {
        # The scan probes the bridge as NVMe, fails Identify Controller, and registers nothing; -d sat is what reaches the ATA disk behind it
        autodetect = false;

        # By-id rather than sdX: the two disks trade letters across boots
        devices = [
            { device = "/dev/disk/by-id/wwn-0x5000c500e81e231d"; options = "-d sat"; }
            { device = "/dev/disk/by-id/ata-SATA_SSD_22020812000605"; options = "-d sat"; }
        ];
    };
}
