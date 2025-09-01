#!/usr/bin/env bash

dconf dump /org/x/pix/ | nix-shell -p dconf2nix --run "dconf2nix --root "org/x/pix/" > 2-dconf-settings.nix"