{
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            # Install Quod Libet directly into user profile
            home.packages = [ pkgs.quodlibet ];

            home = {
                # Persist Quod Libet configurations & library database
                persistence."/Storage/Apps/Fun/Quodlibet" = {
                    directories = [
                        ".config/quodlibet"
                    ];
                };

                # Symlink the autostart desktop entry
                file = {
                    ".config/autostart/io.github.quodlibet.QuodLibet.desktop".source =
                        config.lib.file.mkOutOfStoreSymlink "/home/beatlink/.nix-profile/share/applications/io.github.quodlibet.QuodLibet.desktop";
                };
            };
        };
}
