# Syncthing
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism
#
{ config, inputs, ... }:
{
    sops.secrets.syncthing_cert = {
        sopsFile = "${inputs.self}/secrets/2-server/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_key = {
        sopsFile = "${inputs.self}/secrets/2-server/syncthing.yaml";
        owner = "beatlink";
    };
    services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        cert = config.sops.secrets.syncthing_cert.path;
        key = config.sops.secrets.syncthing_key.path;
        databaseDir = "/Storage/Services/Syncthing/Database";
        dataDir = "/Storage/Services/Syncthing/Data";
        configDir = "/Storage/Services/Syncthing/Config";
        settings = {
            devices = {
                Odin = {
                    addresses = [
                        "tcp://odin.lan:22000"
                        "tcp://odin.technet:22000"
                    ];
                    id = "CSIQ7OW-6MP3FSB-OBDABEA-S53TWYT-N2EFGT6-4FMUV7R-HMXLOF5-GLIW7AD";
                    numConnections = 8;
                };
                Thor = {
                    addresses = [
                        "tcp://thorx.technet:22000"
                        "tcp://thorx.lan:22000"
                    ];
                    id = "VKFKSE5-HAZJGT6-XAT4WG5-MXGCGRE-7XSUVQT-3LLOKOG-4CXV3RA-X2423Q5";
                    numConnections = 8;
                };
            };
            folders = {
                "/Storage/Files/Documents" = {
                    label = "Documents";
                    id = "hz0k1-egjw9";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
                "/Storage/Files/Downloads" = {
                    label = "Downloads";
                    id = "unmbe-b2iab";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
                "/Storage/Files/eBooks" = {
                    label = "eBooks";
                    id = "kj0id-3vcea";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
                "/Storage/Files/Music" = {
                    label = "Music";
                    id = "8g86n-1309l";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendonly";
                };
                "/Storage/Files/Pictures" = {
                    label = "Pictures";
                    id = "ta09s-b2u0y";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
                "/Storage/Files/Projects" = {
                    label = "Projects";
                    id = "xjtvv-cyqwv";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
                "/Storage/Files/Sounds" = {
                    label = "Sounds";
                    id = "kae2q-5740v";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
                "/Storage/Files/Videos" = {
                    label = "Videos";
                    id = "4kqye-6dosm";
                    devices = [
                        "Odin"
                        "Thor"
                    ];
                    type = "sendreceive";
                };
            };
        };
    };

    virtualisation.arion.projects.syncthing = {
        serviceName = "syncthing2";
        settings = {
            services = {
                syncthing.service = {
                    image = "syncthing/syncthing:latest";
                    container_name = "syncthing";
                    hostname = "Heimdall";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/Syncthing:/var/syncthing"
                        "/Storage/Files:/Files"
                    ];
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "APP_BASE_URL" = "syncthing.heimdall.technet";
                    };
                    ports = [
                        "8382:8384"
                        #"22000:22000/tcp" # TCP file transfers
                        #"22000:22000/udp" # QUIC file transfers
                        #"21027:21027/udp" # Receive local discovery broadcasts
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
    nginx-vhosts.syncthing = {
        domain = "syncthing.heimdall.technet";
        port = 8384;
    };

}
