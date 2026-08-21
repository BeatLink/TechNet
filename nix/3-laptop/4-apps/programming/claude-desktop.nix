{ lib, pkgs, ... }:
# Claude Desktop, unpacked from Anthropic's apt .deb and patched for NixOS, as there is no nixpkgs package.
# To update, bump version and take the matching amd64 SHA256 from
# https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
let
    claude-desktop = pkgs.stdenv.mkDerivation rec {
        pname = "claude-desktop";
        version = "1.32885.1";

        src = pkgs.fetchurl {
            url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
            hash = "sha256-+KXd6nyMvnaVic8ZwuGDLV1TKrGb+CAmIbqVfJNRovw=";
        };

        nativeBuildInputs = with pkgs; [
            binutils
            xz
            autoPatchelfHook
            makeWrapper
            copyDesktopItems
        ];

        buildInputs = with pkgs; [
            alsa-lib
            at-spi2-atk
            cairo
            cups
            gtk3
            libdrm
            libcap_ng # bundled virtiofsd
            libgbm
            libnotify
            libseccomp # bundled virtiofsd
            libsecret
            libuuid
            libxkbcommon
            nspr
            nss
            pango
            libx11
            libxcb
            libxcomposite
            libxdamage
            libxext
            libxfixes
            libxrandr
            libxtst
        ];

        # The Electron bundle dlopens these at runtime rather than linking them.
        runtimeDependencies = with pkgs; [
            libglvnd
            libgbm
            libGL
            vulkan-loader
        ];

        # Unpacks the .deb payload, dropping chrome-sandbox since tar cannot restore its setuid mode in the build sandbox.
        unpackPhase = ''
            runHook preUnpack

            ar x $src
            tar -xf data.tar.xz --exclude=./usr/lib/claude-desktop/chrome-sandbox

            runHook postUnpack
        '';

        # Installs the bundle and wraps the launcher for Wayland.
        installPhase = ''
            runHook preInstall

            mkdir -p $out/lib $out/bin $out/share
            cp -r usr/lib/claude-desktop $out/lib/
            cp -r usr/share/icons $out/share/

            # --no-sandbox is required because chrome-sandbox was dropped above and a store path cannot be setuid root.
            # CLAUDE_CODE_LOCAL_BINARY is read but never acted on upstream, so the app still fetches its own CLI into ~/.config/Claude.
            makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
                --add-flags "--no-sandbox" \
                --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true" \
                --set-default ELECTRON_IS_DEV 0 \
                --set-default CLAUDE_CODE_LOCAL_BINARY ${lib.getExe pkgs.claude-code}

            runHook postInstall
        '';

        # Restates the upstream entry so the claude:// handler and its two actions survive.
        desktopItems = [
            (pkgs.makeDesktopItem {
                name = "com.anthropic.Claude";
                desktopName = "Claude";
                genericName = "AI Assistant";
                comment = "Desktop application for Claude.ai";
                exec = "claude-desktop %U";
                icon = "claude-desktop";
                startupNotify = true;
                startupWMClass = "com.anthropic.Claude";
                categories = [
                    "Utility"
                    "Development"
                ];
                keywords = [
                    "AI"
                    "Chat"
                    "Assistant"
                    "Claude"
                    "Code"
                    "LLM"
                ];
                mimeTypes = [ "x-scheme-handler/claude" ];
                actions = {
                    NewChat = {
                        name = "New chat";
                        exec = "claude-desktop claude://claude.ai/new";
                    };
                    NewCode = {
                        name = "New Claude Code session";
                        exec = "claude-desktop claude://code/new";
                    };
                };
            })
        ];

        meta = {
            description = "Desktop application for Claude.ai";
            homepage = "https://claude.ai";
            platforms = [ "x86_64-linux" ];
        };
    };
in
{
    environment.systemPackages = [ claude-desktop ];

    # The CLI the app fetches at runtime is a generic-linux binary, so it needs a real loader rather than NixOS's stub-ld.
    programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
            stdenv.cc.cc.lib # libstdc++/libgcc_s
            zlib
        ];
    };

    home-manager.users.beatlink = {
        home = {
            persistence."/Storage/Apps/AI/ClaudeDesktop" = {
                directories = [
                    ".config/Claude" # App settings, window state and MCP server config
                ];
            };
        };
    };
}
