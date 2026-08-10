# Mobile data
#
# FLOW Jamaica, operator id 338180.
#
# The APN is `ppinternet`, taken from the initial EPS bearer the network itself
# assigned when the modem attached:
#
#     sudo mmcli -b 0
#     Properties | apn: ppinternet
#                | ip type: ipv4
#
# Worth recording where it came from, because the usual source is wrong here:
# mobile-broadband-provider-info has no entry for 338180. Its Jamaica section
# lists Cable & Wireless at 338020 with apn `wap` and Digicel at 338050, neither
# of which is this SIM. FLOW is Cable & Wireless rebranded onto a newer network
# code the database has not caught up with.
#
# The SIM PIN comes from the same sops environment file the WiFi PSKs and the
# WireGuard key use -- NetworkManager substitutes $VARIABLES in profile values
# from `ensureProfiles.environmentFiles`, so the PIN is never written into the
# nix store or the repo. Add it with:
#
#     sops secrets/5-phone/networkmanager.yaml
#     # under networkmanager_env_file, alongside the others:
#     THOR_SIM_PIN=<pin>
#
# With the PIN stored, NetworkManager unlocks the SIM itself on every boot and
# nothing prompts. If a prompt is wanted instead -- so the PIN is never at rest
# on the device -- drop the `pin` line and set `pin-flags = 2`, which makes NM
# ask the session's secret agent, and phosh will put up a dialog after login.
#
{ config, ... }:
{
    networking.networkmanager.ensureProfiles.profiles."FLOW" = {
        connection = {
            id = "FLOW";
            uuid = "3f1a6c74-9e2b-4d58-b0a7-5c8e1f2d9a43";
            type = "gsm";
            autoconnect = true;
        };

        gsm = {
            apn = "ppinternet";
            pin = "$THOR_SIM_PIN";
        };

        ipv4.method = "auto";

        # The bearer reports ip type ipv4, so v6 is left as may-fail rather than
        # required -- an ipv6 = auto that never completes would hold the
        # connection in "connecting" indefinitely.
        ipv6 = {
            method = "auto";
            may-fail = true;
        };
    };
}
