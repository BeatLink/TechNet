{ ... }:
{
    networking.networkmanager.ensureProfiles.profiles."Thor USB Link" = {
        connection = {
            id = "Thor USB Link";
            type = "ethernet";
            autoconnect = "yes";
        };
        ethernet.mac-address = "02:00:00:00:0d:02";
        ipv4 = {
            method = "manual";
            addresses = "172.16.42.2/24";
            never-default = "true";
        };
        ipv6.method = "ignore";
    };
}
