# Steam ##############################################################################################################################################
#
# Steam, GameMode, and the gamescope compositor that games render inside.
#

{
    lib,
    pkgs,
    inputs,
    ...
}:
let
    halonSteamTheme = inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-steam-theme;

    pausedUserUnits = [
        "syncthing.service"
        "syncthingtray.service"
        "vorta.service"
        "gallery-dl-blockurl-sync.timer"
    ];

    pausedSystemUnits = [
        "borgmatic.timer"
        "borgmatic-check.timer"
        "borgmatic-check-data.timer"
        "borg-compact-vorta.timer"
        "zfs-scrub.timer"
        "zfs-snapshot-hourly.timer"
        "zfs-snapshot-daily.timer"
        "zfs-snapshot-weekly.timer"
        "zfs-snapshot-monthly.timer"
        "zpool-trim.timer"
        "fstrim.timer"
        "nix-gc.timer"
        "nixos-upgrade.timer"
    ];

    systemctl = "${pkgs.systemd}/bin/systemctl";

    quietStart = pkgs.writeShellScript "gamemode-quiet-start" ''
        ${systemctl} --user stop ${lib.concatStringsSep " " pausedUserUnits} || true
        ${systemctl} stop ${lib.concatStringsSep " " pausedSystemUnits} || true
    '';

    # A game that dies without gamemode running this hook leaves these stopped until the next boot starts them again.
    quietEnd = pkgs.writeShellScript "gamemode-quiet-end" ''
        ${systemctl} --user start ${lib.concatStringsSep " " pausedUserUnits} || true
        ${systemctl} start ${lib.concatStringsSep " " pausedSystemUnits} || true
    '';
in
{
    config = lib.mkMerge [

        # Steam ######################################################################################################################################
        {
            programs.steam = {
                enable = true;
                package = pkgs.millennium-steam; # Stock Steam plus Millennium's loader, which is what reads the theme below
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
                enableWsi = false; # The FROG WSI bypass layer kills every Vulkan client at startup with "Failed to get Wayland objects", so games never reach their first frame
                args = [
                    "-W"
                    "1920"
                    "-H"
                    "1080"
                    "-r"
                    "120"
                    "-f"
                ]; # Nested gamescope defaults to 1280x720, and the refresh is the faster panel's, since each display still presents at its own rate
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
        # Proton replaces LD_LIBRARY_PATH inside the container, so the preloaded library is given its own directory as an rpath to dlopen from.
        {
            programs.gamemode = {
                enable = true;

                settings = {
                    general = {
                        renice = 10; # Defaults to 0, which leaves the game at the same priority as everything else
                        inhibit_screensaver = 1;
                        script_timeout = 30; # The hooks below stop seventeen units, which does not fit the ten second default
                    };

                    custom = {
                        start = "${quietStart}";
                        end = "${quietEnd}";
                    };
                };
            };

            # gamemode's own polkit rule grants the governor and split lock helpers to this group and nothing else.
            users.users.beatlink.extraGroups = [ "gamemode" ];

            nixpkgs.overlays = [
                (final: prev: {
                    gamemode = prev.gamemode.overrideAttrs (old: {
                        postFixup = (old.postFixup or "") + ''
                            patchelf --add-rpath "$lib/lib" "$lib/lib/libgamemodeauto.so.0.0.0"
                        '';
                    });
                })
            ];
        }

        # Millennium #################################################################################################################################
        # The loader that lets the Steam client wear a CSS theme, and Halon as the theme it wears.
        {
            nixpkgs.overlays = [ inputs.millennium.overlays.default ];

            # Millennium creates its themes directory itself on first run, so the link is a tmpfiles
            # rule that re-asserts itself at every login rather than something written once.
            # Millennium's own docs still give the 2.x location, steamui/skins; 3.x reads this one.
            systemd.user.tmpfiles.rules = [
                "L+ %h/.local/share/Steam/millennium/themes/Halon - - - - ${halonSteamTheme}/share/halon/steam"
            ];
        }

        # Quiet Hours ################################################################################################################################
        # Lets the hooks above stop the maintenance timers, which systemd otherwise only takes from root.
        {
            security.polkit.extraConfig = ''
                polkit.addRule(function (action, subject) {
                    var paused = ${builtins.toJSON pausedSystemUnits};
                    if (action.id == "org.freedesktop.systemd1.manage-units" &&
                        subject.user == "beatlink" &&
                        paused.indexOf(action.lookup("unit")) >= 0) {
                        return polkit.Result.YES;
                    }
                });
            '';
        }

        # Persistence ################################################################################################################################
        {
            home-manager.users.beatlink.home.persistence."/Storage/Apps/Fun/Steam".directories = [
                ".local/share/Steam"
            ];
        }
    ];
}
