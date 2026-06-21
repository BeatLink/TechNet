{
    home-manager.users.beatlink =
        { pkgs, lib, ... }:
        {
            programs.vscodium = {
                enable = true;
                package = pkgs.vscodium;
                # Leave 'extensions' empty here to keep the directory mutable
            };
            home = {
                packages = with pkgs; [
                    nixd
                    nixfmt
                    nil
                ];
                persistence."/Storage/Apps/Programming/VsCodium" = {
                    directories = [
                        ".config/VSCodium"
                        ".local/share/codium"
                        ".vscode-oss"
                    ];
                    files = [ ".config/npmrc" ];

                };
            };
        };
}
