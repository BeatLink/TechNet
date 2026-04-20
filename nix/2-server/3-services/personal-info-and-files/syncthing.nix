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
    sops.secrets.syncthing_gui_password = {
        sopsFile = "${inputs.self}/secrets/2-server/syncthing.yaml";
        owner = "beatlink";
    };
    services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        cert = config.sops.secrets.syncthing_cert.path;
        key = config.sops.secrets.syncthing_key.path;
        user = "beatlink";
        group = "beatlink";
        databaseDir = "/Storage/Services/Syncthing/Database";
        dataDir = "/Storage/Services/Syncthing/Data";
        configDir = "/Storage/Services/Syncthing/Config";
        guiPasswordFile = config.sops.secrets.syncthing_gui_password.path;
        settings = {
            options = {
                urAccepted = -1;
            };
            gui = {
                user = "beatlink";
                insecureSkipHostcheck = true;
            };
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
    nginx-vhosts.syncthing = {
        domain = "syncthing.heimdall.technet";
        port = 8384;
    };

}
