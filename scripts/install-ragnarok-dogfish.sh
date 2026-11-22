#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#Ragnarok
sudo cp -a /run/media/beatlink/d5ae581a-760a-41b1-b01a-82d0b1cec519/@persistent/. /mnt/persistent/
sudo nixos-install --flake .#Ragnarok --root /mnt --no-root-passwd
