# USB Networking #######################

{ pkgs, lib, ... }:
let
    gadget = "/sys/kernel/config/usb_gadget/technet";

    thorMac = "02:00:00:00:00:01";
    hostMac = "02:00:00:00:00:02";

    # Builds the CDC ECM gadget in configfs and binds it to the UDC.
    setupGadget = pkgs.writeShellScript "usb-gadget-setup" ''
        set -eu
        PATH=${
          lib.makeBinPath [
              pkgs.coreutils
              pkgs.kmod
              pkgs.util-linux
          ]
        }:$PATH

        udc=$(ls /sys/class/udc 2>/dev/null | head -1 || true)
        if [ -z "$udc" ]; then
            echo "usb-gadget: no UDC available, skipping"
            exit 0
        fi

        modprobe libcomposite 2>/dev/null || true
        mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config

        if [ -d ${gadget} ]; then
            echo "usb-gadget: already configured"
            exit 0
        fi

        mkdir -p ${gadget}
        cd ${gadget}

        echo 0x1d6b > idVendor
        echo 0x0104 > idProduct
        echo 0x0100 > bcdDevice
        echo 0x0200 > bcdUSB

        mkdir -p strings/0x409
        echo "TechNet" > strings/0x409/manufacturer
        echo "Thor"    > strings/0x409/product
        echo "thor0"   > strings/0x409/serialnumber

        mkdir -p configs/c.1/strings/0x409
        echo "CDC ECM" > configs/c.1/strings/0x409/configuration
        echo 250 > configs/c.1/MaxPower

        mkdir -p functions/ecm.usb0
        echo ${thorMac} > functions/ecm.usb0/dev_addr
        echo ${hostMac} > functions/ecm.usb0/host_addr

        ln -s functions/ecm.usb0 configs/c.1/

        echo "$udc" > UDC
        echo "usb-gadget: bound to $udc"
    '';

    # Unbinds the gadget and removes the configfs tree.
    teardownGadget = pkgs.writeShellScript "usb-gadget-teardown" ''
        set -u
        PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH

        [ -d ${gadget} ] || exit 0
        cd ${gadget}

        echo "" > UDC 2>/dev/null || true

        rm -f configs/c.1/ecm.usb0
        rmdir configs/c.1/strings/0x409 2>/dev/null || true
        rmdir configs/c.1 2>/dev/null || true
        rmdir functions/ecm.usb0 2>/dev/null || true
        rmdir strings/0x409 2>/dev/null || true
        cd /
        rmdir ${gadget} 2>/dev/null || true
    '';
in
{
    # Gadget ---------------------------------------
    services.udev.extraRules = ''
        SUBSYSTEM=="net", ACTION=="add|change", ATTR{address}=="${thorMac}", ENV{NM_UNMANAGED}="0"
    '';

    systemd.services.usb-gadget = {
        description = "USB ECM network gadget";
        wantedBy = [ "multi-user.target" ];
        after = [ "sys-kernel-config.mount" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = setupGadget;
            ExecStop = teardownGadget;
        };
    };

}
