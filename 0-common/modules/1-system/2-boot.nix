# Boot Loader ##########################################################################################################################
#
# This section manages misc boot settings
#
#######################################################################################################################################

{ lib, ... }: 
{
    boot = {
        # Enable Magic SysRq Keys ###################################################################################################################
        kernel.sysctl."kernel.sysrq" = 1;

        # Enable Systemd in init ####################################################################################################################
        initrd.systemd.enable = true;

        # Use Systemd-Boot as Bootloader ############################################################################################################
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            timeout = lib.mkDefault 5;
        };
    };
}