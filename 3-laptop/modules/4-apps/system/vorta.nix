{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ 
                libnotify 
                vorta
                (
                    writeShellScriptBin 
                    "vorta-server-prebackup.sh" 
                    ''
                        #!/usr/bin/env bash
                        until ssh-add -l &> /dev/null 
                        do 
                            notify-send -a "Vorta" "Database Unlock Required" "Please unlock the KeePassXC database for server backups."; 
                            sleep 10; 
                        done 
                        wget --spider "http://uptime-kuma.heimdall.technet/api/push/8ME1iuK3yx?status=up&msg=Backups Started&ping=";
                    ''
                )
                (
                    writeShellScriptBin
                    "vorta-server-postbackup.sh"
                    ''
                        if [ $returncode == 0 ]; then 
                            wget --spider "http://uptime-kuma.heimdall.technet/api/push/8ME1iuK3yx?status=up&msg=Backups Completed&ping="; 
                        else
                            wget --spider "http://uptime-kuma.heimdall.technet/api/push/8ME1iuK3yx?status=down&msg=Backups Failed&ping=";
                        fi
                    ''
                )
            ];
            persistence."/Storage/Apps/System/Vorta" = {
                directories = [
                    ".cache/borg"
                    ".cache/Vorta"
                    ".config/borg"
                    ".local/share/Vorta"
                    ".local/state/Vorta"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/vorta.desktop".source = "${pkgs.vorta}/share/applications/com.borgbase.Vorta.desktop";
            };
        };
    };
}
