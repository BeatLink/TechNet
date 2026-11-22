# SMART Monitoring ###################################################################################################################################
#
# Names both disks explicitly, because smartd's own device scan misreads the JMicron USB bridge and leaves the data drive unmonitored.
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
                device = "/dev/disk/by-id/ata-Dogfish_SSD_64GB_5E56255506071556041";
                options = "-d sat";
            }
        ];
    };
}
