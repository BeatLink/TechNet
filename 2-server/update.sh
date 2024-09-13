#!/usr/bin/env bash
#
# This scripts automatically updates heimdall from this flake
#
nixos-rebuild switch --use-remote-sudo --flake ../#Heimdall --target-host "beatlink@192.168.0.2"

