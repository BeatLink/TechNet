{ pkgs, ... }: {
    # Enable nix-ld to run dynamically downloaded binaries
    programs.nix-ld.enable = true;

    # Expose the missing CUDA libraries to those binaries
    programs.nix-ld.libraries = with pkgs; [
        cudaPackages.nccl
        cudaPackages.cudatoolkit
        stdenv.cc.cc.lib # Often needed by random C++ binaries
        cudaPackages.cuda_cudart
        cudaPackages.cudnn
    ];
    home-manager.users.beatlink =
        { pkgs, ... }:
        let
            fix-jan-nccl = pkgs.writeShellScriptBin "fix-jan-nccl" ''
                set -euo pipefail
                NCCL_LIB="${pkgs.cudaPackages.nccl}/lib/libnccl.so.2"
                shopt -s nullglob
                for dir in "$HOME"/.local/share/Jan/data/llamacpp/backends/*/linux-cuda-*/build/bin; do
                  ln -sf "$NCCL_LIB" "$dir/libnccl.so.2"
                  echo "linked nccl -> $dir"
                done
            '';
        in

        {
            systemd.user.services.fix-jan-nccl = {
                Unit.Description = "Symlink libnccl.so.2 into Jan's llama.cpp backends";
                Service = {
                    Type = "oneshot";
                    ExecStart = "${fix-jan-nccl}/bin/fix-jan-nccl";
                };
                Install.WantedBy = [ "default.target" ]; # <-- add this
            };

            systemd.user.paths.fix-jan-nccl = {
                Unit.Description = "Watch Jan's backend dir for new llama.cpp builds";
                Path.PathModified = "%h/.local/share/Jan/data/llamacpp/backends";
                Install.WantedBy = [ "default.target" ];
            };
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
                packages = with pkgs; [
                    fix-jan-nccl
                    jan
                ];

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
