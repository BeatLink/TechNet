#!/usr/bin/env bash

# Path to the nixtool-config.json file as specified
CONFIG_PATH="/Storage/Files/Projects/TechNet/nixtool-config.json"

# Run the tool via Nix. Replace <GITHUB_URL> with your actual repo URL.
nix run github:BeatLink/NixTool --no-write-lock-file --refresh -- --config "$CONFIG_PATH" "$@"
