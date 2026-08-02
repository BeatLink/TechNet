{ pkgs, ... }:
let
    gadget = "/sys/kernel/config/usb_gadget/technet";

    devMac = "02:00:00:00:0d:01";
    hostMac = "02:00:00:00:0d:02";

    thorAddress = "172.16.42.1";
    odinAddress = "172.16.42.2";

    coreutils = "${pkgs.coreutils}/bin";
    mount = "${pkgs.util-linux}/bin/mount";
    grep = "${pkgs.gnugrep}/bin/grep";
in
{
    technet.tang.addresses = [ odinAddress ];

    boot.initrd = {
        # kernelModules, not availableKernelModules: the latter only places a
        # module in the initrd to be loaded when a device matches it, and nothing
        # binds the gadget framework to a device. Left merely available,
        # /sys/kernel/config/usb_gadget never appears and the service below fails
        # at its first mkdir.
        #
        # The musb controller and the sun4i USB phy are built into the kernel on
        # this platform rather than modules, so only the gadget framework is here.
        kernelModules = [
            "configfs"
            "libcomposite"
            "usb_f_ecm"
        ];

        systemd = {
            storePaths = [
                "${pkgs.coreutils}/bin"
                "${pkgs.util-linux}/bin/mount"
                "${pkgs.gnugrep}/bin/grep"
            ];

            services.usb-gadget = {
                description = "Expose a CDC ECM gadget so initrd can reach tang over USB";
                wantedBy = [ "initrd.target" ];
                after = [ "systemd-modules-load.service" ];
                before = [ "systemd-networkd.service" ];
                unitConfig.DefaultDependencies = "no";
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                };
                script = ''
                    set -eu

                    if ! ${grep} -q ' /sys/kernel/config ' /proc/mounts; then
                        ${coreutils}/mkdir -p /sys/kernel/config
                        ${mount} -t configfs none /sys/kernel/config
                    fi

                    if [ -e ${gadget}/UDC ] && [ -s ${gadget}/UDC ]; then
                        echo "usb-gadget: already bound"
                        exit 0
                    fi

                    ${coreutils}/mkdir -p ${gadget}/strings/0x409
                    echo 0x1d6b > ${gadget}/idVendor
                    echo 0x0104 > ${gadget}/idProduct
                    echo TechNet > ${gadget}/strings/0x409/manufacturer
                    echo "Thor initrd unlock" > ${gadget}/strings/0x409/product
                    echo thor > ${gadget}/strings/0x409/serialnumber

                    ${coreutils}/mkdir -p ${gadget}/configs/c.1/strings/0x409
                    echo "CDC ECM" > ${gadget}/configs/c.1/strings/0x409/configuration

                    ${coreutils}/mkdir -p ${gadget}/functions/ecm.usb0
                    echo ${hostMac} > ${gadget}/functions/ecm.usb0/host_addr
                    echo ${devMac} > ${gadget}/functions/ecm.usb0/dev_addr
                    ${coreutils}/ln -sfn ${gadget}/functions/ecm.usb0 ${gadget}/configs/c.1/ecm.usb0

                    udc="$(${coreutils}/ls /sys/class/udc | ${coreutils}/head -n1)"
                    if [ -z "$udc" ]; then
                        echo "usb-gadget: no UDC found, cannot bind gadget" >&2
                        exit 1
                    fi
                    echo "$udc" > ${gadget}/UDC
                    echo "usb-gadget: bound to $udc"
                '';
            };

            network = {
                enable = true;
                networks."10-usb0" = {
                    matchConfig.Name = "usb0";
                    address = [ "${thorAddress}/24" ];
                    networkConfig.LinkLocalAddressing = "no";
                };
            };
        };
    };
}
