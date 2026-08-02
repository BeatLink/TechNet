#  Mosquitto
#
#  The MQTT broker every device on the network reports through. Home Assistant,
#  Frigate and both LNXlink instances are its clients, and Vigil probes it; it is
#  filed under home automation because that is what most of the traffic is, but
#  more than home automation depends on it.
#
#  Split three ways:
#
#    broker.nix         the broker itself -- accounts, ACLs and the local listener
#    remote-access.nix  how a host that is not Heimdall reaches it
#    web-ui.nix         the browser client, and the websockets listener it needs
#
#  The broker only ever listens on 127.0.0.1. Everything that comes in from
#  elsewhere arrives through nginx, which owns the TechNet certificate.
{
    imports = [
        ./broker.nix
        ./remote-access.nix
        ./web-ui.nix
    ];
}
