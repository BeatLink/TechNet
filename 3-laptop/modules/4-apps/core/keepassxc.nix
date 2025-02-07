{lib, ...}:
{
    services.gnome.gnome-keyring.enable  = lib.mkForce false;
    security.pam.services.login.kwallet.enable = false;
    home-manager.users.beatlink = { pkgs, ... }: {
        services.gnome-keyring.enable = lib.mkForce false;
        home = {
            packages = with pkgs; [ keepassxc ];
            persistence."/Storage/Apps/Core/KeePassXC" = {
                directories = [
                    ".config/keepassxc"
                    ".cache/keepassxc"                   
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/org.keepassxc.KeePassXC.desktop".source = "${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop";
            };
        };
    };
}
