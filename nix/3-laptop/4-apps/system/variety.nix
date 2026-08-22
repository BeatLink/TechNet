{
    config,
    lib,
    pkgs,
    ...
}:
{
    environment.systemPackages = with pkgs; [ variety ];
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        let
            # Cinnamon's lock screen reuses the desktop background and exposes no key aiming it elsewhere
            setLockScreen = pkgs.writeShellScript "variety-set-lock-screen" ''
                exit 0
            '';
        in
        {
            home = {
                file = {
                    ".config/autostart/variety.desktop".source =
                        "${pkgs.variety}/share/applications/variety.desktop";
                    # Variety's own copy handles neither Cinnamon nor Hyprland and exits 1 on every change
                    ".config/variety/scripts/set_lock_screen".source = setLockScreen;
                };
                persistence."/Storage/Apps/System/Variety" = {
                    directories = [
                        ".config/variety"
                    ];

                };
            };
        };
}
