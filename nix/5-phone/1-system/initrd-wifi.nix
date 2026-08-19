# WiFi in initrd #####################################################################################################################################
{
    config,
    pkgs,
    ...
}:
let
    interface = "wld0";
    confPath = config.sops.templates."wpa_supplicant-initrd.conf".path;
    plymouth = "${config.boot.plymouth.package}/bin/plymouth";
in
{
    # Credentials ------------------------------------------------------------------------------------------------------------------------------------
    sops.secrets.technet_wifi_password = {
        sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";
    };

    # Might be a security risk, PSK in initrd, consider certificate based auth
    sops.templates."wpa_supplicant-initrd.conf" = {
        content = ''
            ctrl_interface=/run/wpa_supplicant
            network={
                ssid="TechNet Wi-Fi"
                psk="${config.sops.placeholder.technet_wifi_password}"
            }
        '';
        mode = "0400";
    };

    # Initrd -----------------------------------------------------------------------------------------------------------------------------------------
    boot.initrd = {
        secrets."${confPath}" = confPath;

        systemd = {
            storePaths = [ "${pkgs.wpa_supplicant}/bin/wpa_supplicant" ];

            services.wpa_supplicant-initrd = {
                description = "Associate with WiFi so clevis can reach tang";

                bindsTo = [ "sys-subsystem-net-devices-${interface}.device" ];
                after = [
                    "sys-subsystem-net-devices-${interface}.device"
                    "initrd-nixos-copy-secrets.service"
                ];
                wantedBy = [ "sys-subsystem-net-devices-${interface}.device" ];
                before = [ "systemd-networkd.service" ];

                unitConfig = {
                    DefaultDependencies = "no"; # Needed to prevent a dependency loop
                    StartLimitIntervalSec = 0;
                };
                serviceConfig = {
                    Type = "simple";
                    Restart = "on-failure";
                    RestartSec = 2;
                    ExecStartPre = ''-${plymouth} display-message --text="Connecting to Wi-Fi..."'';
                    ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_supplicant -i ${interface} -c ${confPath}";
                };
            };

            network = {
                enable = true;
                wait-online.timeout = 30;
                networks."20-${interface}" = {
                    matchConfig.Name = interface;
                    networkConfig.DHCP = "yes";
                    linkConfig.RequiredForOnline = "routable";
                };
            };
        };
    };

    # Discards initrd systemd-networkd state that nothing updates.
    systemd.services.clear-initrd-networkd-state = {
        description = "Discard initrd systemd-networkd state that nothing updates";
        wantedBy = [ "sysinit.target" ];
        before = [ "systemd-timesyncd.service" ];
        unitConfig = {
            # Needed to prevent a dependency loop; without it systemd deletes dbus-broker to break the cycle
            DefaultDependencies = "no";
            ConditionPathExists = "/run/systemd/netif";
        };
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.coreutils}/bin/rm -rf /run/systemd/netif";
        };
    };
}
