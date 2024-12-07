#!/usr/bin/env bash
#
# This scripts automatically updates heimdall from this flake
#
nixos-rebuild \
    --flake ../../#Odin \
    --target-host "beatlink@$1" \
    --build-host "beatlink@$1" \
    --use-remote-sudo \
    switch 
