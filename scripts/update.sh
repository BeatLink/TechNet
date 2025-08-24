#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash gum

# Main Variables ---------------------------------------------------------------------------
FLAKE_DIR=$(cd "$(dirname "$0")/../"; pwd)
CURRENT_HOST=$(hostname)
CURRENT_USER=$(whoami)
HOSTS=("Odin" "Heimdall" "Ragnarok")

# Helper Functions -------------------------------------------------------------------------
title() {
    gum style --foreground "#00ACFF" --border-foreground "#00ACFF" \
        --border thick --align center --width 150 --margin "1 0" \
        --padding "1 2" "$@"
}

pr() {
    gum style --foreground "#00ACFF" "$@"
}

choose() {
    gum choose --item.foreground "#00ACFF" --header.foreground "#00ACFF" \
        --cursor.foreground "#00ACFF" --header "$1" "${@:2}"
}

get_hosts() {
    local selected
    selected=$(choose "Select Hosts:" "All Hosts" "${HOSTS[@]}")
    if [[ "$selected" == "All Hosts" ]]; then
        echo "${HOSTS[@]}"
    else
        echo "$selected"
    fi
}

get_rebuild_action() {
    local action
    action=$(choose "Select Nixos-Rebuild Action:" \
        "switch        - Activate config and save to bootloader" \
        "test          - Activate config but reset next boot" \
        "boot          - Activate config on next boot" \
        "dry-activate  - Build config but only show changes" \
        "build-vm      - Build Test VM" \
        "rollback      - Rollback to previous configuration")
    echo "$action" | cut -d'-' -f1 | awk '{$1=$1;print}'
}

run_on_hosts() {
    local hosts=($1)
    local func=$2
    shift 2
    for host in "${hosts[@]}"; do
        "$func" "$host" "$@"
    done
}

# Nixos-Rebuild Function -------------------------------------------------------------------
nixos_rebuild() {
    local host="$1"
    local host_lower=${host,,}
    local params=()
    local sudo_cmd=""

    if [[ "$CURRENT_HOST" == "$host" ]]; then
        sudo_cmd="sudo"
        params=(--flake "$FLAKE_DIR#$host")
    else
        params=(--flake "$FLAKE_DIR#$host" \
                --build-host "$CURRENT_USER@$host_lower.technet" \
                --target-host "$CURRENT_USER@$host_lower.technet" \
                --no-reexec \
                --sudo \
                --ask-sudo-password)
    fi

    local final_cmd="$sudo_cmd nixos-rebuild ${params[@]} $NIXOS_REBUILD_ACTION"
    bash -c "$final_cmd"
}

# Remove Old Generations Function ----------------------------------------------------------
remove_generations() {
    local host="$1"
    local dry_run="$2"

    if [[ "$CURRENT_HOST" == "$host" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            echo "---- $host (system generations) ----"
            sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
            echo "---- $host (user generations) ----"
            nix-env --list-generations
        else
            sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old
            nix-env --delete-generations old
        fi
    else
        if [[ "$dry_run" == "true" ]]; then
            ssh "$CURRENT_USER@$host.technet" "echo '---- $host (system generations) ----' && sudo nix-env --profile /nix/var/nix/profiles/system --list-generations && echo '---- $host (user generations) ----' && nix-env --list-generations"
        else
            ssh "$CURRENT_USER@$host.technet" "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old && nix-env --delete-generations old"
        fi
    fi
}

# Nix Garbage Collection Function ----------------------------------------------------------
nix_gc() {
    local host="$1"
    ssh "$CURRENT_USER@$host.technet" nix-collect-garbage -d
}

# Main Script ------------------------------------------------------------------------------
title 'TechNet Updater' '' 'This script automatically updates the selected Host from this flake'

COMMAND=$(choose "Select Command:" \
    "Run All Tasks" \
    "Run Nix Flake Update" \
    "Run Nixos Rebuild" \
    "Preview Old Generations" \
    "Remove Old Generations + GC" \
    "Run Nix Garbage Collection"
)

case "$COMMAND" in
    "Run All Tasks")
        HOST_LIST=($(get_hosts))
        NIXOS_REBUILD_ACTION=$(get_rebuild_action)
        gum confirm "Run the following tasks on ${HOST_LIST[*]}?
1. Update Flake
2. nixos-rebuild $NIXOS_REBUILD_ACTION
3. Remove Old Generations
4. nix-collect-garbage" || exit 1

        nix flake update --flake "$FLAKE_DIR"
        run_on_hosts "${HOST_LIST[*]}" nixos_rebuild
        run_on_hosts "${HOST_LIST[*]}" remove_generations false
        run_on_hosts "${HOST_LIST[*]}" nix_gc
        ;;

    "Run Nix Flake Update")
        nix flake update --flake "$FLAKE_DIR"
        ;;

    "Run Nixos Rebuild")
        HOST_LIST=($(get_hosts))
        NIXOS_REBUILD_ACTION=$(get_rebuild_action)
        gum confirm "Run nixos-rebuild $NIXOS_REBUILD_ACTION on ${HOST_LIST[*]}?" || exit 1
        run_on_hosts "${HOST_LIST[*]}" nixos_rebuild
        ;;

    "Preview Old Generations")
        HOST_LIST=($(get_hosts))
        run_on_hosts "${HOST_LIST[*]}" remove_generations true
        ;;

    "Remove Old Generations + GC")
        HOST_LIST=($(get_hosts))
        gum confirm "Remove old generations and run GC on ${HOST_LIST[*]}?" || exit 1
        run_on_hosts "${HOST_LIST[*]}" remove_generations false
        run_on_hosts "${HOST_LIST[*]}" nix_gc
        ;;

    "Run Nix Garbage Collection")
        HOST_LIST=($(get_hosts))
        gum confirm "Run nix-collect-garbage on ${HOST_LIST[*]}?" || exit 1
        run_on_hosts "${HOST_LIST[*]}" nix_gc
        ;;
esac
