
{config, ...}: {
    sops.secrets.syncthing_cert.sopsFile = ../../../secrets.yaml;
    sops.secrets.syncthing_key.sopsFile = ../../../secrets.yaml;
    home-manager.users.beatlink = { pkgs, ... }: {
        home.packages = with pkgs; [ syncthingtray-minimal ];
        systemd.user.services.syncthing.serviceConfig.SupplementaryGroups = ["keys"];
        systemd.user.targets.tray = {
            Unit = {
                Description = "Home Manager System Tray";
                Requires = [ "graphical-session-pre.target" ];
            };
        };
        services.syncthing = {
            enable = true;
            tray = {
                enable = true;
                command = "syncthingtray --wait";
            };
            guiAddress = "odin.technet:8384";
            cert = config.sops.secrets.syncthing_cert.path;
            key = config.sops.secrets.syncthing_key.path;
            settings = {
                devices = {
                    Heimdall = {
                        addresses = [
                            "tcp://192.168.0.2:22000"
                            "tcp://10.100.100.1:22000"
                            "udp://192.168.0.2:22000"
                            "udp://10.100.100.1:22000"
                        ];
                        id = "Q6AIAK4-4PFLB3Z-73QF54Y-EKQ2LC5-5FSVFRZ-RBGWFDI-KZQI45E-JBXXTQY";
                    };
                    Thor = {
                        addresses = [
                            "tcp://192.168.0.5:22000"
                            "tcp://10.100.100.4:22000"
                            "udp://192.168.0.5:22000"
                            "udp://10.100.100.4:22000"
                        ];
                        id = "IZOOSHB-MWRVHH7-HVEVB4P-UVR7NIU-UD4ZJBW-GBGY6EE-OOY2PLM-2IE32QT";
                    };
                };
                folders = {
                    "/Storage/Files/Documents" = {
                        label = "Documents";
                        id = "hz0k1-egjw9";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                    "/Storage/Files/Downloads" = {
                        label = "Downloads";
                        id = "unmbe-b2iab";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                    "/Storage/Files/eBooks" = {
                        label = "eBooks";
                        id = "kj0id-3vcea";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                    "/Storage/Files/Music" = {
                        label = "Music";
                        id = "8g86n-1309l";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendonly";
                    };
                    "/Storage/Files/Pictures" = {
                        label = "Pictures";
                        id = "ta09s-b2u0y";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                    "/Storage/Files/Projects" = {
                        label = "Projects";
                        id = "xjtvv-cyqwv";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                    "/Storage/Files/Sounds" = {
                        label = "Sounds";
                        id = "kae2q-5740v";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                    "/Storage/Files/Videos" = {
                        label = "Videos";
                        id = "4kqye-6dosm";
                        devices = [ "Heimdall" "Thor" ];
                        type = "sendreceive";
                    };
                };
            };
        };
        home = {
            persistence."/Storage/Apps/TechNet/SyncThing" = {
                directories = [
                    ".local/state/syncthing"
                ];
                files = [
                    ".config/syncthingtray.ini"
                ];
                allowOther = true;
            };
        };
    };
}

