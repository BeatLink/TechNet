#!/usr/bin/env bash
#
# This scripts automatically updates heimdall from this flake
#
nixos-rebuild \
    --flake ../../#Heimdall \
    --target-host "beatlink@192.168.0.2" \
    --build-host "beatlink@192.168.0.2" \
    --use-remote-sudo \
    --ask-sudo-password \
    switch 
