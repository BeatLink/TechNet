#!/usr/bin/env bash
#
# This scripts automatically updates Ragnarok from this flake
#

FLAKEDIR=$(cd "$(dirname "$0")/../../"; pwd);

# Needed to provision initrd secrets before theyre used

nixos-rebuild \
    --flake "$FLAKEDIR"#Ragnarok \
    --build-host "beatlink@ragnarok" \
    --target-host "beatlink@ragnarok" \
    --sudo  \
    --no-reexec \
    test


nixos-rebuild \
    --flake "$FLAKEDIR"#Ragnarok \
    --build-host "beatlink@ragnarok" \
    --target-host "beatlink@ragnarok" \
    --sudo  \
    --no-reexec \
    switch

#"beatlink@ragnarok.technet"