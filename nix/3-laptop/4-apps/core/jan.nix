{ pkgs, ... }: {
    environment.systemPackages = [ pkgs.lmstudio ];
    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/AI/LMStudio" = {
                directories = [
                    ".config/LM Studio" # App UI preferences and Electron state
                    ".lmstudio" # Main folder: models, chats, presets, extensions & CLI binaries
                ];
            };
        };
    };
}
