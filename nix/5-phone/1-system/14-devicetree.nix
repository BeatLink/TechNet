# Device tree
#
# The WiFi chip is never given time to come up. mmc-pwrseq-simple releases the
# RTL8723CS from reset and the host probes it almost immediately -- 37ms from
# controller init to giving up:
#
#   sunxi-mmc 1c10000.mmc: allocated mmc-pwrseq
#   sunxi-mmc 1c10000.mmc: initialized, max. request size: 16384 KB
#   mmc2: Failed to initialize a non-removable card
#
# The PinePhone's wifi-pwrseq node carries only compatible and reset-gpios.
# Boards that bring this chip up successfully also set post-power-on-delay-ms,
# conventionally 200. The node is equally bare in the kernel's own DTB at 6.12
# and 6.18, so this is a gap in the upstream device tree rather than Tow-Boot
# passing a stale one.
#
# The delay is the change actually being tested. ext_clock is left alone for now:
# mainline does not wire one here either, and adding a second unverified change
# at the same time would make a failure impossible to attribute.
#
{ ... }:
{
    hardware.deviceTree = {
        enable = true;
        name = "allwinner/sun50i-a64-pinephone-1.2.dtb";

        overlays = [
            {
                name = "pinephone-wifi-pwrseq-delay";
                dtsText = ''
                    /dts-v1/;
                    /plugin/;

                    / {
                        fragment@0 {
                            target-path = "/wifi-pwrseq";
                            __overlay__ {
                                post-power-on-delay-ms = <200>;
                            };
                        };
                    };
                '';
            }
        ];
    };
}
