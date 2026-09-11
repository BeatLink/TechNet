# Boot ###############################################################################################################################################
#
# Console output for a headless board: the HDMI stack loaded from the initrd, and the serial console on ttyS2.
# Also the clock, whose RTC has no battery, and the journal, which an unclean shutdown keeps corrupting.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Console Output #############################################################################################################################
        {
            boot.kernelParams = [
                "console=ttyS2,115200n8"
                "console=tty0" # Last console listed becomes /dev/console, so userspace output lands on HDMI
            ];

            # Send Journal logs to serial and hdmi
            services.journald.settings.Journal = {
                ForwardToConsole = true;
                TTYPath = "/dev/ttyS2";
            };
        }

        # Journal Persistence ########################################################################################################################
        {
            services.journald.settings.Journal = {
                Storage = "persistent";
                SyncIntervalSec = "1min";
            };
        }
    ];
}
