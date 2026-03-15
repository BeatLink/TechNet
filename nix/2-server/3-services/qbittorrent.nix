# Qbittorrent
#
# Qbittorrent is the torrent management server. The torrent server allows for automatic 24/7 downloading and setting of content.
#
# https://hub.docker.com/r/linuxserver/qbittorrent
#

{
    virtualisation.arion.projects.qbittorrent = {
        serviceName = "qbittorrent";
        settings = {
            services = {
                qbittorrent.service = {
                    image = "lscr.io/linuxserver/qbittorrent:latest";
                    container_name = "qbittorrent";
                    hostname = "qbittorrent";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "WEBUI_PORT" = "8080";
                        "TORRENTING_PORT" = "6881";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [
                        "/Storage/Services/Qbittorrent/config:/config"
                        "/Storage/Files/Downloads:/downloads"
                    ];
                    expose = [
                        "8080"
                    ];
                    ports = [
                        "6881:6881"
                        "6881:6881/udp"
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
