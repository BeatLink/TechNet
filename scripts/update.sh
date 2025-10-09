#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash gum

# Main Variables ---------------------------------------------------------------------------
FLAKE_DIR=$(cd "$(dirname "$0")/../"; pwd)
CURRENT_HOST=$(hostname)
CURRENT_USER=$(whoami)
HOSTS=("Odin" "Heimdall" "Ragnarok" "Thor")

# Helper Functions -------------------------------------------------------------------------
title() {
    gum style --foreground "#00ACFF" --border-foreground "#00ACFF" \
        --border thick --align center --width 150 --margin "1 0" \
        --padding "1 2" "$@"
}

pr() {
    local timestamp
    timestamp=$(date +"[%H:%M:%S]")
    gum style --foreground "#00ACFF" "$timestamp $*"
}

success() {
    local timestamp
    timestamp=$(date +"[%H:%M:%S]")
    gum style --foreground "#00FF7F" "$timestamp $*"
}

fail() {
    local timestamp
    timestamp=$(date +"[%H:%M:%S]")
    gum style --foreground "#FF4C4C" "$timestamp ❌ $*"
}

run_checked() {
    local cmd="$*"
    eval "$cmd"
    if [[ $? -ne 0 ]]; then
        fail "Command failed: $cmd"
        exit 1
    fi
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

# Robust run_on_hosts supporting extra arguments ------------------------------------------
run_on_hosts() {
    local func=$1
    shift
    local hosts=()
    local func_args=()

    # Collect extra args before the special --hosts marker
    while [[ "$#" -gt 0 ]]; do
        if [[ "$1" == "--hosts" ]]; then
            shift
            break
        fi
        func_args+=("$1")
        shift
    done

    # Remaining args are hosts
    hosts=("$@")

    for host in "${hosts[@]}"; do
        "$func" "$host" "${func_args[@]}"
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
            run_checked "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old"
            run_checked "nix-env --delete-generations old"
        fi
    else
        if [[ "$dry_run" == "true" ]]; then
            ssh "$CURRENT_USER@$host.technet" "echo '---- $host (system generations) ----' && sudo nix-env --profile /nix/var/nix/profiles/system --list-generations && echo '---- $host (user generations) ----' && nix-env --list-generations"
        else
            run_checked "ssh $CURRENT_USER@$host.technet 'sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old && nix-env --delete-generations old'"
        fi
    fi
}

# Nix Garbage Collection Function ----------------------------------------------------------
nix_gc() {
    local host="$1"
    run_checked "ssh $CURRENT_USER@$host.technet nix-collect-garbage -d"
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

        pr "🔄 Updating flake..."
        run_checked nix flake update --flake "$FLAKE_DIR"

        pr "⚙️  Running nixos-rebuild $NIXOS_REBUILD_ACTION..."
        run_on_hosts nixos_rebuild --hosts "${HOST_LIST[@]}"

        pr "🗑️  Removing old generations..."
        run_on_hosts remove_generations false --hosts "${HOST_LIST[@]}"

        pr "🧹 Running garbage collection..."
        run_on_hosts nix_gc --hosts "${HOST_LIST[@]}"

        success "✅ All tasks completed successfully!"
        ;;

    "Run Nix Flake Update")
        pr "🔄 Updating flake..."
        run_checked nix flake update --flake "$FLAKE_DIR"
        success "✅ Flake update completed!"
        ;;

    "Run Nixos Rebuild")
        HOST_LIST=($(get_hosts))
        NIXOS_REBUILD_ACTION=$(get_rebuild_action)
        gum confirm "Run nixos-rebuild $NIXOS_REBUILD_ACTION on ${HOST_LIST[*]}?" || exit 1
        pr "⚙️  Running nixos-rebuild $NIXOS_REBUILD_ACTION..."
        run_on_hosts nixos_rebuild --hosts "${HOST_LIST[@]}"
        success "✅ nixos-rebuild $NIXOS_REBUILD_ACTION completed!"
        ;;

    "Preview Old Generations")
        HOST_LIST=($(get_hosts))
        pr "👀 Previewing old generations on ${HOST_LIST[*]}..."
        run_on_hosts remove_generations true --hosts "${HOST_LIST[@]}"
        success "✅ Preview complete!"
        ;;

    "Remove Old Generations + GC")
        HOST_LIST=($(get_hosts))
        gum confirm "Remove old generations and run GC on ${HOST_LIST[*]}?" || exit 1
        pr "🗑️  Removing old generations..."
        run_on_hosts remove_generations false --hosts "${HOST_LIST[@]}"
        pr "🧹 Running garbage collection..."
        run_on_hosts nix_gc --hosts "${HOST_LIST[@]}"
        success "✅ Old generations removed and GC completed!"
        ;;

    "Run Nix Garbage Collection")
        HOST_LIST=($(get_hosts))
        gum confirm "Run nix-collect-garbage on ${HOST_LIST[*]}?" || exit 1
        pr "🧹 Running garbage collection..."
        run_on_hosts nix_gc --hosts "${HOST_LIST[@]}"
        success "✅ Garbage collection completed!"
        ;;
esac
