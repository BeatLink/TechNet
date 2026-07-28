{ lib, pkgs, ... }:
let
    # Claude Desktop is only shipped as a .deb from Anthropic's apt repo; there is no
    # nixpkgs package. Unpack the prebuilt Electron bundle and patch it for NixOS.
    # To update: bump version, then take the SHA256 for the matching amd64 .deb from
    # https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
    claude-desktop = pkgs.stdenv.mkDerivation rec {
        pname = "claude-desktop";
        version = "1.24012.9";

        src = pkgs.fetchurl {
            url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
            hash = "sha256-MC5tII3YyOnlIGfaoo7zsRcaFhNYb9DhC+3GQiJbbuE=";
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
            libcap_ng # bundled virtiofsd (VM-backed sandbox)
            libgbm
            libnotify
            libseccomp # bundled virtiofsd (VM-backed sandbox)
            libsecret
            libuuid
            libxkbcommon
            nspr
            nss
            pango
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            xorg.libxcb
            xorg.libXtst
        ];

        # The Electron bundle dlopens these at runtime rather than linking them.
        runtimeDependencies = with pkgs; [
            libglvnd
            libgbm
            libGL
            vulkan-loader
        ];

        # chrome-sandbox is setuid in the .deb and tar cannot restore that mode in the
        # build sandbox, so extract the payload directly and skip it.
        unpackPhase = ''
            runHook preUnpack

            ar x $src
            tar -xf data.tar.xz --exclude=./usr/lib/claude-desktop/chrome-sandbox

            runHook postUnpack
        '';

        installPhase = ''
            runHook preInstall

            mkdir -p $out/lib $out/bin $out/share
            cp -r usr/lib/claude-desktop $out/lib/
            cp -r usr/share/icons $out/share/

            # chrome-sandbox was excluded above since it needs root setuid, which a Nix
            # store path cannot have, so run Electron with its sandbox disabled.
            # At runtime the app downloads a generic-linux `claude` CLI into
            # ~/.config/Claude/claude-code and execs it. That binary is not patched for
            # NixOS, so it needs nix-ld to supply a real loader (enabled below).
            # CLAUDE_CODE_LOCAL_BINARY looks like it would point the app at a Nix-built
            # CLI instead, but in 1.24012.9 the constructor only evaluates the variable
            # and never calls initLocalBinary(), so the override is dead code upstream.
            # It is set anyway to take effect if a later release wires it up.
            makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
                --add-flags "--no-sandbox" \
                --set-default ELECTRON_IS_DEV 0 \
                --set-default CLAUDE_CODE_LOCAL_BINARY ${lib.getExe pkgs.claude-code}

            runHook postInstall
        '';

        # Preserve the upstream .desktop entry, including its claude:// scheme handler
        # and the New chat / New Claude Code session actions.
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

    # The app fetches its own unpatched `claude` CLI at runtime and execs it, so that
    # binary needs a real dynamic loader rather than NixOS's stub-ld.
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
