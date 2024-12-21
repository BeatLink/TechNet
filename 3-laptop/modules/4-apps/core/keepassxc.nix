{ config, lib, pkgs, ... }:
let
    keepassxc-ssh-prompt = pkgs.writeShellScript  "keepassxc-ssh-prompt.sh" ''
        until ssh-add -l &> /dev/null
        do
            echo "Waiting for agent. Please unlock the database."
            flatpak run org.keepassxc.KeePassXC &> /dev/null
            sleep 1
        done

        /usr/bin/nc "$1" "$2"
    '';
 in {
    services.flatpak.packages = ["flathub:app/org.keepassxc.KeePassXC//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Core/KeePassXC" = {
                directories = [
                    ".var/app/org.keepassxc.KeePassXC"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/org.keepassxc.KeePassXC.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/exports/share/applications/org.keepassxc.KeePassXC.desktop";

                ".config/plank/dock1/launchers/org.keepassxc.KeePassXC.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/org.keepassxc.KeePassXC.desktop
                '';
            };
        };
    };
    programs.ssh.extraConfig = ''
        ProxyCommand ${keepassxc-ssh-prompt} %h %p
    '';
}