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

        # php generates the keymap header, sdcc builds the 8051 firmware itself. megi warns that sdcc older than 4.1 miscompiles it.
        nativeBuildInputs = [
            pkgs.php
            pkgs.sdcc
        ];

        # The firmware's own build script is /bin/bash, which the sandbox has not got.
        postPatch = ''
            patchShebangs firmware/build.sh
        '';

        # The Makefile stamps a version from git describe, which is not a repository here.
        makeFlags = [ "VERSION=${"4f31294"}" ];

        installPhase = ''
            runHook preInstall
            install -Dm755 -t $out/bin build/ppkb-*
            install -Dm644 -t $out/share/pinephone-keyboard build/fw-stock.bin
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
