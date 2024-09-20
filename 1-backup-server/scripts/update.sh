#!/usr/bin/env bash
#
# This scripts automatically updates Ragnarok from this flake
#
nixos-rebuild \
    --flake ../../#Ragnarok \
    --build-host "pearson@10.100.100.5" \
    --target-host "pearson@10.100.100.5" \
    --use-remote-sudo  \
    --fast \
    switch

