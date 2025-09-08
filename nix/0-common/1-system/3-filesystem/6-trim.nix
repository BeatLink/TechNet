# Enable TRIM for SSDs and NVMEs
{
    services = {
        fstrim.enable = true;
        zfs.trim.enable = true;
    };
}
