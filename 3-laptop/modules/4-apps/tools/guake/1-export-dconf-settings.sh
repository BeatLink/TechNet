#!/usr/bin/env bash

dconf dump /org/guake/ | nix-shell -p dconf2nix --run "dconf2nix --root "org/guake/" > 2-dconf-settings.nix"