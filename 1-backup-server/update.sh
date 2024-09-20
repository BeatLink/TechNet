#!/usr/bin/env bash
#
# This scripts automatically updates Ragnarok from this flake
#
nixos-rebuild switch --use-remote-sudo --flake ../#Ragnarok --target-host "beatlink@10.100.100.5"

