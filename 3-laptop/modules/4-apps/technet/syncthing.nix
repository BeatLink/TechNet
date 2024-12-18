{ config, pkgs, ... }: 
{
    # services.flatpak.packages = [ "flathub:app/com.borgbase.Vorta//stable" ];
    
    
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            services.syncthing = {
                enable = true;
                tray.enable = true;
                settings = {
                    devices = {
                        Heimdall = {
                            addresses = [
                                "tcp://192.168.0.2:51820"
                                "tcp://10.100.100.1:51820"
                            ];
                            id = "Q6AIAK4-4PFLB3Z-73QF54Y-EKQ2LC5-5FSVFRZ-RBGWFDI-KZQI45E-JBXXTQY"
                        };
                        Thor = {
                            addresses = [
                                "tcp://192.168.0.5:51820"
                                "tcp://10.100.100.4:51820"
                            ];
                            id = "IZOOSHB-MWRVHH7-HVEVB4P-UVR7NIU-UD4ZJBW-GBGY6EE-OOY2PLM-2IE32QT"
                        };
                    };
                    folders = {
                        "/Storage/Files/Documents" = {
                            label = "Documents";
                            id = "hz0k1-egjw9";
                            devices = [ "Heimdall" "Thor" ];
                            type = "sendreceive";
                        };
                    };
                };


            };
    
    
    
            /*persistence."/Storage/Apps/System/Vorta" = {
                directories = [
                    ".var/app/com.borgbase.Vorta"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/com.borgbase.Vorta.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/exports/share/applications/com.borgbase.Vorta.desktop";
            };*/
        };
    };
}

