# Nitrox #############################################################################################################################################
#
# The Subnautica multiplayer mod, taken from upstream's native Linux build as there is no nixpkgs package.
# To update, bump version and take the new hash from nix-prefetch-url --unpack.
#

{ lib, pkgs, ... }:
let
    nitrox = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "nitrox";
        version = "1.8.1.0";

        src = pkgs.fetchzip {
            url = "https://github.com/SubnauticaNitrox/Nitrox/releases/download/${finalAttrs.version}/Nitrox_${finalAttrs.version}_linux_x64.zip";
            hash = "sha256-TQEZjFVKRaQPRshJk6j18hLG9mihLOVrd8ZpzhJtRF0=";
            stripRoot = false;
        };

        icon = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/SubnauticaNitrox/Nitrox/${finalAttrs.version}/Nitrox.Launcher/Assets/Images/nitrox-icon.ico";
            hash = "sha256-Dicz3QXAgL4UtRVRDRb3MLrZMnOK+QdxsNbTwV6E0ZY=";
        };

        nativeBuildInputs = with pkgs; [
            makeWrapper
            copyDesktopItems
            imagemagick
        ];

        # Skia and Avalonia's X11 backend dlopen these, so they have to be on the wrapper's library path.
        runtimeLibraries = with pkgs; [
            fontconfig
            freetype
            libx11
            libice
            libsm
            libxi
            libxrandr
            libxcursor
            libxext
            libglvnd
            zlib
        ];

        # Installs the published .NET assemblies and wraps each entry point in the dotnet runtime that runs it.
        installPhase = ''
            runHook preInstall

            mkdir -p $out/share/nitrox $out/share/icons/hicolor/64x64/apps
            cp -r . $out/share/nitrox

            for app in Launcher Server.Subnautica; do
                makeWrapper ${lib.getExe pkgs.dotnet-runtime_9} $out/bin/nitrox-$app \
                    --add-flags $out/share/nitrox/Nitrox.$app.dll \
                    --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.runtimeLibraries}
            done
            mv $out/bin/nitrox-Launcher $out/bin/nitrox
            mv $out/bin/nitrox-Server.Subnautica $out/bin/nitrox-server

            magick "$icon[3]" $out/share/icons/hicolor/64x64/apps/nitrox.png

            runHook postInstall
        '';

        desktopItems = [
            (pkgs.makeDesktopItem {
                name = "nitrox";
                desktopName = "Nitrox";
                genericName = "Subnautica Multiplayer";
                comment = "Multiplayer mod for Subnautica";
                exec = "nitrox";
                icon = "nitrox";
                categories = [ "Game" ];
            })
        ];

        meta = {
            description = "Multiplayer mod for Subnautica";
            homepage = "https://nitrox.rux.gg";
            mainProgram = "nitrox";
            platforms = [ "x86_64-linux" ];
        };
    });
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ nitrox ];
            persistence."/Storage/Apps/Fun/Nitrox" = {
                directories = [
                    ".config/Nitrox" # Launcher settings, hosted server saves and logs
                ];
            };
        };
    };
}
