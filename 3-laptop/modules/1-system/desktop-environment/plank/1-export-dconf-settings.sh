#!/usr/bin/env bash


dconf dump /net/launchpad/plank/ | nix-shell -p dconf2nix --run "dconf2nix --root "/net/launchpad/plank" > 2-dconf-settings.nix"