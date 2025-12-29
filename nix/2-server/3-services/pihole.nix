# Pi-Hole
#
# Pi-Hole acts as an ad-blocking system for the TechNet. More importantly, it also acts as the DNS server for all docker services and hosts
# in the TechNet, allowing them to be accessed via the .technet domain
#
# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
#
# Links:
#     - https://github.com/pi-hole/pi-hole/
#
# Device List
#     - Heimdall - heimdall.technet
#     - Odin - odin.technet
#     - Hela - hela.technet
#     - Thor - thor.technet
#     - ThorX - thorx.technet
#     - Ragnarok - ragnarok.technet
#

{ config, inputs, ... }:
{
    sops.secrets.pihole_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    virtualisation.arion.projects.pihole = {
        serviceName = "pihole";
        settings = {
            services = {
                pihole.service = {
                    image = "pihole/pihole:latest";
                    container_name = "pihole";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/PiHole/etc-pihole:/etc/pihole"
                        "/Storage/Services/PiHole/etc-dnsmasq.d:/etc/dnsmasq.d"
                    ];
                    env_file = [
                        config.sops.secrets.pihole_env.path
                    ];
                    capabilities = {
                        SYS_NICE = true;
                        SYS_TIME = true;
                    };
                    environment = {
                        "TZ" = "America/Jamaica";
                        "WEB_PORT" = "80";
                    };
                    expose = [
                        "80"
                    ];
                    ports = [
                        "53:53/tcp"
                        "53:53/udp"
                        "82:443/tcp"
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                };
            };
            networks = {
                nginx-proxy-manager_public = {
                    external = true;
                };
            };
        };
    };
}
