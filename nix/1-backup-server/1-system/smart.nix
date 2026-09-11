# SMART Monitoring ###################################################################################################################################
#
# Names both USB disks explicitly, because smartd's own device scan misreads the JMicron bridge and leaves the data drive unmonitored.
#

{
    services.smartd = {
        autodetect = false;
        devices = [
            {
                device = "/dev/disk/by-id/wwn-0x5000c500e81e231d";
                options = "-d sat";
            }
            {
                device = "/dev/disk/by-id/ata-SATA_SSD_22020812000605";
                options = "-d sat";
            }
        ];
    };
}
