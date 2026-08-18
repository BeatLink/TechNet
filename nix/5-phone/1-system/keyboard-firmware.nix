# Keyboard firmware tools #############################################################################################################################
#
# megi's host-side tools for the case's MCU. Only `info` and the user-firmware slot are reachable over i2c from the phone; replacing the stock firmware
# needs a USB cable soldered to the controller board, so nothing here can flash the power-consumption fix on its own.
#
{ pkgs, ... }:
let
    pinephone-keyboard-tools = pkgs.stdenv.mkDerivation {
        pname = "pinephone-keyboard-tools";
        version = "0-unstable-4f31294";

        # megous.com is the upstream but resolves intermittently; smaeul's mirror is the kernel driver author's own.
        src = pkgs.fetchFromGitHub {
            owner = "smaeul";
            repo = "pinephone-keyboard";
            rev = "4f312940656191ceabc7e0b7f609894b7f419a2d";
            hash = "sha256-xqjOn2NV6riZ6YNMdv6nLiAjLn4a2+toD0qDkUvMnyA=";
        };

        # php generates the keymap header; sdcc is only needed to build the firmware itself, which this does not.
        nativeBuildInputs = [ pkgs.php ];

        makeFlags = [ "tools" ];

        installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            install -Dm755 build/ppkb-* $out/bin/
            runHook postInstall
        '';

        meta = {
            description = "Host tools for the PinePhone keyboard case MCU and its IP5209 charger";
            homepage = "https://xnux.eu/pinephone-keyboard/";
            license = pkgs.lib.licenses.gpl3Plus;
            platforms = pkgs.lib.platforms.linux;
        };
    };
in
{
    environment.systemPackages = [ pinephone-keyboard-tools ];
}
