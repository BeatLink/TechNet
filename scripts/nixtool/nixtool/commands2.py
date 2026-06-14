import pathlib
import json

nix_flake_update = {
    "name": "Run Nix Flake Update",
    "commands": [
        "nix flake update --refresh"
    ],
    "run_on_remote": False
}

def get_dconf_commands(flake_path):
    queue = []
    flake_root = pathlib.Path(flake_path)
    for config_path in flake_root.rglob("dconf-settings.json"):
        try:
            data = json.loads(config_path.read_text())
            for dconf_path in data.get("dconf_exports", []):
                output_name = f"{dconf_path.strip('/').replace('/', '.')}.dconf"
                target_file = (config_path.parent / output_name).relative_to(flake_root)
                queue.append(f"dconf dump {dconf_path} > ./{target_file}")
        except Exception as e:
            queue.append(f"echo 'Error processing {config_path.name}: {str(e)}'")
    return queue if queue else ["echo 'No localized dconf targets found.'"]


export_dconf = {
    "name": "Export Dconf Settings",
    "commands": [
        get_dconf_commands
    ],
    "run_on_remote": False
}

nix_rebuild = {
    "name": "Run Nixos Rebuild",
    "commands": [
        "nixos-rebuild"
        "--sudo"
        "--no-reexec"
        "--show-trace"
        "--flake <FLAKEPATH>#<HOSTNAME>"
        "--target-host <USER>@<HOSTNAME>"
        "<ACTION>"
    ],
    "menu_variables": {
        "ACTION": {
            "title": "Select a NixOS Rebuild action",
            "type": "list"
            "options": {
                "switch": "switch - Activate config and save to bootloader",
                "test": "test - Activate config but reset next boot",
                "boot": "boot - Activate config on next boot",
                "dry-activate": "dry-activate - Build config but only show changes",
                "build-vm": "build-vm - Build Test VM",
                "rollback": "rollback - Rollback to previous configuration"
            }
        }
    },
    "run_on_remote": True
}


nix_preview_generations = {
    "name": "Preview Old Generations",
    "commands": [
        'echo "---- <HOSTNAME> (system generations) ----"',
        'sudo nix-env --profile /nix/var/nix/profiles/system --list-generations',
        'echo "---- <HOSTNAME> (user generations) ----"',
        'nix-env --list-generations'
    ],
    "run_on_remote": True
}

nix_purge_generations = {
    "name": "Remove Old Generations",
    "commands": [
        "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old",
        "nix-env --delete-generations old"
    ],
    "run_on_remote": True
}

nix_gc = {
    "name": "Run Garbage Collection",
    "commands": [
        "sudo nix-collect-garbage -d"
    ],
    "run_on_remote": True
}

nix_purge_generations_gc = {
    "name": "Remove Old Generations & GC",
    "commands": [
        nix_preview_generations,
        nix_purge_generations,
        nix_gc
    ]
}

run_all = {
    "name": "Run All Tasks",
    "commands": [
        nix_flake_update,
        nix_rebuild,
        nix_preview_generations,
        nix_purge_generations,
        nix_gc
    ],
    "run_on_remote": True
}

all_commands = {
    "title": "Select a command",
    "commands": [
        run_all,
        nix_flake_update,
        export_dconf,
        nix_rebuild,
        nix_preview_generations,
        nix_purge_generations,
        nix_purge_generations_gc,
    ]
}
