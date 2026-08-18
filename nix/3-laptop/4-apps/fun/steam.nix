# Steam ##############################################################################################################################################
#
# Steam, GameMode, and the gamescope compositor that games render inside.
#

{ lib, pkgs, ... }:
{
    config = lib.mkMerge [

        # Steam ######################################################################################################################################
        {
            programs.steam = {
                enable = true;
                remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
                dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
                localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
            };
            environment.systemPackages = with pkgs; [ protonup-qt ];
        }

        # Gamescope ##################################################################################################################################
        # Flags and environment ride on the gamescope wrapper, so a per-game launch option only has to name gamescope.
        {
            programs.gamescope = {
                enable = true;
                capSysNice = true; # Lets gamescope renice itself, which is what keeps its own thread ahead of the game under load
                enableWsi = true;
                args = [
                    "-W"
                    "1920"
                    "-H"
                    "1080"
                    "-r"
                    "75"
                    "-f"
                ]; # Nested gamescope defaults to 1280x720, so the output size has to be stated
                env = {
                    __NV_PRIME_RENDER_OFFLOAD = "1";
                    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
                    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
                    __VK_LAYER_NV_optimus = "NVIDIA_only";
                    __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
                }; # Puts gamescope itself on the dGPU alongside the game, which costs one PRIME copy instead of two
            };
        }

        # Steam Session ##############################################################################################################################
        # A display-manager session that runs Steam inside gamescope, so games launched from it need no launch option at all.
        {
            programs.steam.gamescopeSession.enable = true;
        }

        # GameMode ###################################################################################################################################
        {
            programs.gamemode.enable = true;
        }

        # Persistence ################################################################################################################################
        {
            home-manager.users.beatlink.home.persistence."/Storage/Apps/Fun/Steam".directories = [ ".local/share/Steam" ];
        }
    ];
}
