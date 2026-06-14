#!/usr/bin/env nix-shell
#! nix-shell -i python
#! nix-shell -p python313 python3Packages.textual nh

import sys
import pathlib

# Add src to path for local development/nix-shell usage
src_path = str(pathlib.Path(__file__).parent.parent.parent / "src")
sys.path.insert(0, src_path)

from nixtool import run

if __name__ == "__main__":
    # Locate the config file relative to the entrypoint
    config_path = pathlib.Path(__file__).parent / "nixtool-config.json"
    run(config_path=config_path)