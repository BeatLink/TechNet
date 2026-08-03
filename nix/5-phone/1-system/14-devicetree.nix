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
# The overlay is applied here rather than through hardware.deviceTree.overlays,
# which silently produced an unpatched tree -- verified by decompiling the result
# both ways. fdtoverlay resolves &wifi_pwrseq through the base tree's __symbols__
# node, so the overlay must be compiled with -@ to carry the matching __fixups__.
#
# Only the delay is changed. ext_clock is left alone: mainline does not wire one
# here either, and two unverified changes at once would make a failure
# impossible to attribute.
#
{ config, lib, pkgs, ... }:
let
    dtbName = "allwinner/sun50i-a64-pinephone-1.2.dtb";

    patchedDtbs = pkgs.runCommand "pinephone-dtbs-wifi-delay" {
        nativeBuildInputs = [ pkgs.dtc ];
    } ''
        mkdir -p "$out/allwinner"

        cat > overlay.dts <<'EOF'
        /dts-v1/;
        /plugin/;
        &wifi_pwrseq {
            post-power-on-delay-ms = <200>;
        };
        EOF

        dtc -@ -I dts -O dtb -o overlay.dtbo overlay.dts
        fdtoverlay \
            -i "${config.boot.kernelPackages.kernel}/dtbs/${dtbName}" \
            -o "$out/${dtbName}" \
            overlay.dtbo

        # Fail loudly rather than shipping a tree that silently lacks the fix.
        if ! dtc -I dtb -O dts "$out/${dtbName}" 2>/dev/null | grep -q "post-power-on-delay-ms"; then
            echo "overlay did not apply to $out/${dtbName}" >&2
            exit 1
        fi
    '';
in
{
    hardware.deviceTree = {
        enable = true;
        name = dtbName;
        package = lib.mkForce patchedDtbs;
    };
}
