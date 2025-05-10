#!/usr/bin/env bash
#
# This scripts automatically updates heimdall from this flake
#
nixos-rebuild \
    --flake ../../#Heimdall \
    --target-host "beatlink@10.100.100.1" \
    --build-host "beatlink@10.100.100.1" \
    --use-remote-sudo \
    switch 
