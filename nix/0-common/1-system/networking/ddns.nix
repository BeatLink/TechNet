# DDNS Hostname ######################################################################################################################################
#
# The home connection has no static address, so a dynamic-DNS name stands in for it: the WireGuard endpoint every roaming host dials, the record Vigil
# keeps current, and the name Pi-hole pins to a LAN address indoors. That name identifies the house, so it is a secret rather than a literal.
#
# Every host gets the decrypted value here. Nothing reads the file directly -- consumers render it into whatever shape they need through a sops
# template, which is what keeps the name out of the nix store and lets each of them own the rendered file as its own service user.
#

{ config, ... }:
{
    sops.secrets.ddns_hostname.sopsFile = "${config.technet.secrets.commonPath}/ddns.yaml";
}
