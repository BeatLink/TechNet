#!/usr/bin/env bash


dconf dump /org/blueman/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/blueman/" > 2-dconf-settings.nix"