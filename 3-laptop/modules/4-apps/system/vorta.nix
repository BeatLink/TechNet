{ config, pkgs, ... }: 


let 
    prebackupCommand = pkgs.writeShellScript "vorta-prebackup.sh" ''
        flatpak-spawn --host notify-send -a "Vorta" "Database Unlock Required" "Please unlock the KeePassXC database for server backups."; 
        flatpak run org.keepassxc.KeePassXC &> /dev/null; 
        until ssh-add -l &> /dev/null 
        do 
            sleep 10; 
        done 
        wget --spider "http://uptime-kuma.heimdall.technet/api/push/8ME1iuK3yx?status=up&msg=Backups Started&ping=";
    '';
in {
    environment.systemPackages = with pkgs; [ libnotify ];
    services.flatpak.packages = [ "flathub:app/com.borgbase.Vorta//stable" ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/System/Vorta" = {
                directories = [
                    ".var/app/com.borgbase.Vorta"
                ];
                allowOther = true;
            };
            file = {
                ".var/app/com.borgbase.Vorta/vorta-prebackup.sh".source = prebackupCommand;
                ".config/autostart/com.borgbase.Vorta.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/exports/share/applications/com.borgbase.Vorta.desktop";
            };
        };
    };
}

