# Traccar ############################################################################################################################################
#
# The GPS tracking server, receiving over the OsmAnd protocol alone: Thor posts its geoclue fix to port 5055, and no other decoder is started.
#
# 5055 is deliberately not in `allowedTCPPorts`. It is reachable because wireguard0 is a trusted interface, so every peer in the TechNet can post to
# it; the device id in each report is what Traccar matches against a device, not the firewall.
#
# Devices and users live only in the database -- there is no declarative provisioning of either. Two things therefore have to be done once in the web
# UI: add a device whose identifier is `thor`, and add a read-only `vigil` user whose password matches secrets/2-server/traccar.yaml, which is what the
# device-staleness monitor authenticates as.
#
{ config, ... }:
{
    # Read by whichever Vigil transport runs the `cat` -- the agent today, vigil-access as fallback
    sops.secrets.traccar_vigil_password = {
        sopsFile = "${config.technet.secrets.path}/traccar.yaml";
        group = "vigil-monitor";
        mode = "0440";
    };

    services.traccar = {
        enable = true;
        settings = {
            web = {
                port = "9280";
                url = "traccar.heimdall.technet";
            };

            # An allow-list rather than the whole decoder set, so the only port this listens on is the one Thor reports to
            protocols.enable = "osmand";
            osmand.port = "5055";
        };
    };

    environment.persistence."/Storage/Services/Traccar".directories = [ "/var/lib/private/traccar" ];

    nginx-vhosts.traccar = {
        domain = "traccar.heimdall.technet";
        port = 9280;
    };
}
