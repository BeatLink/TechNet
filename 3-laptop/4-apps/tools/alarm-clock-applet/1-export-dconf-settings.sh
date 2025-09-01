#!/usr/bin/env bash

dconf dump /io/github/alarm-clock-applet/ | nix-shell -p dconf2nix --run "dconf2nix --root "io/github/alarm-clock-applet/" > 2-dconf-settings.nix"