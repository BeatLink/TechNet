#!/usr/bin/env bash
#
# This scripts automatically updates Ragnarok from this flake
#

FLAKEDIR=$(cd "$(dirname "$0")/../../"; pwd);

# Needed to provision initrd secrets before theyre used

nixos-rebuild \
    --flake "$FLAKEDIR"#Ragnarok \
    --build-host "beatlink@192.168.0.52" \
    --target-host "beatlink@192.168.0.52" \
    --no-reexec \
    --sudo  \
    --ask-sudo-password \
    test


nixos-rebuild \
    --flake "$FLAKEDIR"#Ragnarok \
    --build-host "beatlink@192.168.0.52" \
    --target-host "beatlink@192.168.0.52" \
    --no-reexec \
    --sudo  \
    --ask-sudo-password \
    switch

#"beatlink@ragnarok.technet"