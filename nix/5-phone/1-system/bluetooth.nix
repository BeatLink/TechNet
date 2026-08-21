# Bluetooth
#
# Re-probe the radio once the firmware is actually reachable.
#
# The failure looked like missing firmware and was not:
#
#     Bluetooth: hci0: RTL: loading rtl_bt/rtl8723cs_xx_fw.bin
#     bluetooth hci0: Direct firmware load for rtl_bt/rtl8723cs_xx_fw.bin
#                     failed with error -2
#     Bluetooth: hci0: RTL: firmware file rtl_bt/rtl8723cs_xx_fw not found
#
# rtl8723cs_xx_fw.bin and rtl8723cs_xx_config.bin are both in nixpkgs'
# linux-firmware and both are in this host's merged hardware.firmware set.
# firmware_class.path points at that set. megi's kernel has
# CONFIG_FW_LOADER_COMPRESS_ZSTD=y, so the .zst files are readable. Every part
# of the chain is present.
#
# It is a timing problem. The driver probes at 2.08s, and the pools this host
# keeps /nix on are not imported until roughly 20s -- ZFS is not even loaded
# until 4.58s. So the firmware is asked for while the filesystem holding it does
# not exist yet, the request fails with ENOENT, and nothing ever asks again:
# btrtl gives up permanently and leaves hci0 registered but without firmware.
#
# Unbinding and rebinding runs the probe a second time, and by then the store is
# there. Confirmed on the running phone -- the rebind logs both blobs loading,
# `RTL: fw version 0xaa5ca4dc`, and hci0 reaching UP RUNNING with a real BD
# address.
#
# This is worth preferring over the alternative of copying the firmware into the
# initrd. That would work, but it puts a second copy of a blob in the boot image
# to work around ordering, and it would need repeating for any other device that
# wants firmware early. Re-probing addresses the actual cause.
#
{ pkgs, ... }:
{
    # The radio stays down until it is asked for, rather than drawing power on every boot.
    hardware.bluetooth.powerOnBoot = false;

    # powerOnBoot only writes AutoEnable=false, which governs bluetoothd. systemd-rfkill restores the soft block saved at shutdown, and the kernel
    # keeps its own powered setting, so a radio left on comes back unblocked and powers itself straight up with bluetoothd never consulted.
    systemd.services.bluetooth-rfkill-block = {
        description = "Start with the Bluetooth radio blocked, whatever state it was left in";
        wantedBy = [ "multi-user.target" ];

        # After the rebind, which replaces the rfkill device and so gets its saved state restored a second time.
        after = [
            "bluetooth-firmware-rebind.service"
            "bluetooth.service"
        ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.util-linux}/bin/rfkill block bluetooth";
        };
    };

    systemd.services.bluetooth-firmware-rebind = {
        description = "Re-probe the Bluetooth radio once its firmware is reachable";
        wantedBy = [ "multi-user.target" ];

        # The store has to be mounted, which on this host means the root pool is
        # imported and /nix is up -- true for anything in stage 2. Before
        # bluetooth.service so bluetoothd sees a radio that already has firmware
        # rather than one that has to be re-enumerated underneath it.
        after = [ "local-fs.target" ];
        before = [ "bluetooth.service" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "bluetooth-firmware-rebind" ''
                driver=/sys/bus/serial/drivers/hci_uart_h5
                device=serial0-0

                # Nothing bound means nothing to re-probe -- a kernel that
                # enumerated it differently, or no radio at all. Not an error.
                if [ ! -e "$driver/$device" ]; then
                    echo "bluetooth-firmware-rebind: $device not bound to hci_uart_h5, nothing to do"
                    exit 0
                fi

                echo "$device" > "$driver/unbind"
                # The serdev teardown is not instant and binding too soon fails
                # with EBUSY, which would leave the radio unbound entirely --
                # worse than the state this is fixing.
                sleep 2
                echo "$device" > "$driver/bind"
            '';
        };
    };
}
