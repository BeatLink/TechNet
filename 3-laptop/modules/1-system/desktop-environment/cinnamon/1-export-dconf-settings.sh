#!/usr/bin/env bash


dconf dump /org/cinnamon/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/cinnamon/" > 2-dconf-settings.nix"