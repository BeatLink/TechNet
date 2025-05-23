#!/usr/bin/env bash

dconf dump /com/gexperts/Tilix/ | nix-shell -p dconf2nix --run "dconf2nix --root "com/gexperts/Tilix/" > 2-dconf-settings.nix"