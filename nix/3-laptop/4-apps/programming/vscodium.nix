{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [
                    nixd
                    nixfmt
                    vscodium
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
