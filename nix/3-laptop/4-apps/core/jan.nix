{ pkgs, ... }: {
    # Enable nix-ld to run dynamically downloaded binaries
    programs.nix-ld.enable = true;

    # Expose the missing CUDA libraries to those binaries
    programs.nix-ld.libraries = with pkgs; [
        cudaPackages.nccl
        cudaPackages.cudatoolkit
        stdenv.cc.cc.lib # Often needed by random C++ binaries
    ];
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            # ... your existing setup ...
            xdg.desktopEntries.jan-nvidia = {
                name = "Jan (NVIDIA)";
                genericName = "Local AI Desktop";
                # %u allows the app to handle deep-links (like model downloads from the browser)
                exec = "nvidia-offload Jan %u";
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
