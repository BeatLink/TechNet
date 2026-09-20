# LM Studio
#
# Desktop runner for local LLMs. It downloads its own llama.cpp runtimes on
# first launch, so the only GPU piece needed from NixOS is the CUDA driver.
#
{ ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ pkgs.lmstudio ];

                persistence."/Storage/Apps/AI/LMStudio" = {
                    directories = [
                        ".lmstudio" # Models, chats, presets and the downloaded runtimes
                        ".config/LM Studio" # Window state and app preferences
                    ];
                };
            };
        };
}
