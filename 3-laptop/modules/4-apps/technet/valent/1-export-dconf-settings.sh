#!/usr/bin/env bash


dconf dump /ca/andyholmes/valent/ | nix-shell -p dconf2nix --run "dconf2nix --root "/ca/andyholmes/valent/" > 2-dconf-settings.nix"