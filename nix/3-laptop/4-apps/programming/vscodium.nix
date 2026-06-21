{
    home-manager.users.beatlink =
        { pkgs, lib, ... }:
        let
            basePath = ".vscode-oss";
            continuePkg = pkgs.vscode-extensions.continue.continue;
            continueDirName = lib.toLower "${continuePkg.vscodeExtPublisher}.${continuePkg.vscodeExtName}-${continuePkg.version}-linux-x64";
        in
        {
            programs.vscode = {
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
                file."${basePath}/extensions/${continueDirName}" = {
                    source = "${pkgs.vscode-extensions.continue.continue}/share/vscode/extensions/${continuePkg.vscodeExtPublisher}.${continuePkg.vscodeExtName}";
                };
            };
        };
}
