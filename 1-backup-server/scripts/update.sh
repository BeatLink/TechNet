#!/usr/bin/env bash
#
# This scripts automatically updates Ragnarok from this flake
#

FLAKEDIR=$(cd "$(dirname "$0")/../../"; pwd);
nixos-rebuild \
    --flake "$FLAKEDIR"#Ragnarok \
    --build-host "beatlink@ragnarok.technet" \
    --target-host "beatlink@ragnarok.technet" \
    --use-remote-sudo  \
    --fast \
    switch

