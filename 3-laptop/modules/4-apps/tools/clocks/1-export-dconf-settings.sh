#!/usr/bin/env bash

dconf dump /org/gnome/clocks/ | nix-shell -p dconf2nix --run "dconf2nix --root "/org/gnome/clocks/" > 2-dconf-settings.nix"