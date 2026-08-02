# Kernel
#
# Pinned to 6.12 because WiFi does not come up on 6.13 or later. The RTL8723CS
# sits on SDIO behind mmc-pwrseq-simple, whose probe fails and takes the whole
# MMC host with it, so rtw88 never sees a device and no wlan interface is created:
#
#   pwrseq_simple wifi-pwrseq: error -ENOENT: reset control not ready
#   pwrseq_simple wifi-pwrseq: probe with driver pwrseq_simple failed with error -2
#
# The chain, from the 6.18 sources:
#
#   - The PinePhone's wifi-pwrseq node has exactly one reset-gpios and no resets
#     property, so pwrseq_simple takes its reset-CONTROLLER path.
#   - RESET_GPIO defaults to =m, and the reset core tests IS_ENABLED, which is
#     true for a module. So the "absent optional reset returns NULL" early-out is
#     skipped and it tries to synthesise a reset-gpio device instead.
#   - __reset_add_reset_gpio_device() handles only #gpio-cells=2 and returns
#     -ENOENT for anything else. Allwinner pinctrl uses 3 cells (bank, pin,
#     flags), so it always fails here.
#   - pwrseq_simple treats that as fatal rather than deferring, and never reaches
#     its GPIO fallback, which would have handled 3 cells perfectly well.
#
# A regression from 73bf4b7381f7 ("mmc: pwrseq_simple: add support for one reset
# control") in v6.13-rc1, reported upstream for the same error on another
# Allwinner board. The fix there is still an unmerged RFC.
#
# 6.12 predates that commit, and both it and its ZFS module are in the binary
# cache, so this costs a download rather than a kernel build.
#
{ pkgs, ... }:
{
    boot.kernelPackages = pkgs.linuxPackages_6_12;

    # The alternative, for when moving back to a current kernel: turning
    # RESET_GPIO off restores the pre-6.13 behaviour exactly -- IS_ENABLED is
    # false, the optional lookup returns NULL, and pwrseq falls through to
    # devm_gpiod_get_array(), which handles 3 cells. Nothing on this device
    # declares a GPIO-backed reset controller, so nothing else wants it.
    #
    # It is not a cached configuration, so it costs a full kernel build.
    #
    # boot.kernelPatches = [
    #     {
    #         name = "no-reset-gpio";
    #         patch = null;
    #         extraStructuredConfig.RESET_GPIO = lib.mkForce lib.kernel.no;
    #     }
    # ];
}
