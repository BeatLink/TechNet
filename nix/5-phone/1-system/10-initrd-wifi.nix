# WiFi in initrd
#
# Clevis unlocks the root pool by fetching a share from Odin's tang server, which
# means initrd needs a network. On Ragnarok and Heimdall that is free: ethernet
# comes up with no credentials and no configuration worth the name. Thor has no
# ethernet, so the initrd has to associate with WiFi before anything can be
# unlocked, and that needs wpa_supplicant.
#
# This replaces the CDC ECM USB gadget that used to serve the same purpose, which
# only worked while the phone was tethered to Odin and needed the ANX7688 driver
# mainline does not have.
#
# SECURITY: the WiFi PSK ends up readable by anyone holding the phone.
#
# sops cannot run in initrd -- its age identity is the host SSH key on
# /persistent, which is inside the encrypted pool this is trying to unlock. So
# the credential is copied in with boot.initrd.secrets, exactly as
# 2-initrd-wireguard.nix does for the wireguard key, and the initrd lives on the
# unencrypted ESP. That is inherent to unlocking over WiFi rather than a flaw in
# how it is done here: something outside the encrypted volume must hold enough to
# join the network.
#
# The wireguard key is already exposed the same way, so this changes the degree
# rather than the kind. Worth knowing all the same, and worth rotating the PSK
# rather than shrugging if the phone is ever lost.
#
{
    config,
    pkgs,
    ...
}:
let
    # Renamed from wlan0 by udev -- `rtl8723cs mmc2:0001:1 wld0: renamed from wlan0`.
    # The rename happens in initrd too, since the same udev rules are used.
    interface = "wld0";

    confPath = config.sops.templates."wpa_supplicant-initrd.conf".path;
in
{
    # The PSK on its own. NetworkManager takes the whole env file, but a template
    # can only substitute individual secrets, so the same password is also
    # exposed as its own key.
    sops.secrets.technet_wifi_password = {
        sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";
    };

    # Rendered from sops on the running system, then copied into the initrd
    # below. Only the one network: initrd needs to reach tang, not to roam.
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

    boot.initrd = {
        # RTL8723CS is built into megi's kernel and its firmware is carried in the
        # driver, so unlike the bluetooth side there is no firmware file to ship.
        # Nothing to add to availableKernelModules.

        # sops does not run in initrd, so the rendered config is injected at
        # nixos-rebuild time instead. It never enters the nix store.
        secrets."${confPath}" = confPath;

        systemd = {
            storePaths = [ "${pkgs.wpa_supplicant}/bin/wpa_supplicant" ];

            services.wpa_supplicant-initrd = {
                description = "Associate with WiFi so clevis can reach tang";
                wantedBy = [ "initrd.target" ];
                # Must follow the secret being copied in, and precede networkd:
                # DHCP cannot succeed before association.
                after = [ "initrd-nixos-copy-secrets.service" ];
                before = [ "systemd-networkd.service" ];
                unitConfig.DefaultDependencies = "no";
                serviceConfig = {
                    Type = "simple";
                    # Not a oneshot and nothing waits on it. Association can take
                    # a while or never happen -- away from home there is no
                    # TechNet Wi-Fi at all -- and a boot that blocks on it would
                    # be worse than one that falls through to the passphrase
                    # prompt, which still works.
                    Restart = "on-failure";
                    RestartSec = 5;
                    ExecStart = "${pkgs.wpa_supplicant}/bin/wpa_supplicant -i ${interface} -c ${confPath}";
                };
            };

            # DHCP on the WiFi link. Under systemd initrd this is
            # boot.initrd.systemd.network, not boot.initrd.network -- the latter
            # configures the scripted initrd, which is not in use here.
            #
            # RequiredForOnline is off for the same reason the service does not
            # block: away from this network the boot must fall through to the
            # passphrase prompt rather than wait.
            network = {
                enable = true;
                networks."20-${interface}" = {
                    matchConfig.Name = interface;
                    networkConfig.DHCP = "yes";
                    linkConfig.RequiredForOnline = "no";
                };
            };
        };
    };
}
