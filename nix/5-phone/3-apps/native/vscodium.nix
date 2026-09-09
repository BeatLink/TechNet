# VSCodium, wrapped for Wayland.
#
# Electron, so the same rule as chromium.nix: bare, it looks for a display it cannot find under phosh and
# exits. NIXOS_OZONE_WL is not set in this session, and the wrapper would ignore it anyway, so the flags it
# would have added are spelled out -- the last two are what the phone's keyboard types through.
#
# --disable-gpu because Chromium's GPU process was measured dying repeatedly on this Mali-400 while trying
# to get a context it cannot have; software rendering is the only stable configuration here.
#
{ pkgs, ... }:
let
    vscodium-wayland = pkgs.symlinkJoin {
        name = "vscodium-wayland";
        paths = [ pkgs.vscodium ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/codium \
                --add-flags "--ozone-platform=wayland" \
                --add-flags "--disable-gpu" \
                --add-flags "--enable-wayland-ime=true" \
                --add-flags "--wayland-text-input-version=3"
        '';
    };
in
{
    home-manager.users.beatlink = {
        home = {
            packages = [ vscodium-wayland ];

            persistence."/Storage/Apps/Core/VSCodium" = {
                directories = [
                    ".config/VSCodium"
                    ".vscode-oss"
                ];
            };
        };
    };
}
