{
    programs.fuse.userAllowOther = true;
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ nixd nixfmt-rfc-style vscodium ];
            persistence."/Storage/Apps/Programming/VsCodium" = {
                directories = [
                    ".config/VSCodium"
                    ".local/share/codium"                    
                    ".vscode-oss"
                ];
                files = [".config/npmrc"];
                allowOther = true;
            };
        };
    };
}
