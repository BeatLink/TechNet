{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [
                    libnotify
                    vorta
                ];
                persistence."/Storage/Apps/System/Vorta" = {
                    directories = [
                        ".cache/borg"
                        ".cache/Vorta"
                        ".config/borg"
                        ".local/share/Vorta"
                        ".local/state/Vorta"
                    ];
                };
                file = {
                    ".config/autostart/vorta.desktop".source =
                        "${pkgs.vorta}/share/applications/com.borgbase.Vorta.desktop";
                };
            };
        };
}
