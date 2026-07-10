{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            # ... your existing setup ...
            xdg.desktopEntries.jan-nvidia = {
                name = "Jan (NVIDIA)";
                genericName = "Local AI Desktop";
                # %u allows the app to handle deep-links (like model downloads from the browser)
                exec = "nvidia-offload jan %u";
                icon = "jan";
                terminal = false;
                categories = [
                    "Utility"
                    "Development"
                ];
                type = "Application";
            };
            home = {
                packages = with pkgs; [ jan ];

                persistence."/Storage/Apps/AI/Jan" = {
                    directories = [
                        ".config/Jan"
                        ".cache/Jan"
                        ".local/share/Jan" # This is the crucial one (contains your models and chats)
                    ];
                };
            };
        };
}
