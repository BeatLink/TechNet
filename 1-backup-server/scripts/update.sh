#!/usr/bin/env bash
#
# This scripts automatically updates Ragnarok from this flake
#

FLAKEDIR=$(cd "$(dirname "$0")/../../"; pwd);
nixos-rebuild \
    --flake "$FLAKEDIR"/#Ragnarok \
    --build-host "beatlink@10.100.100.5" \
    --target-host "beatlink@10.100.100.5" \
    --use-remote-sudo  \
    --fast \
    switch

