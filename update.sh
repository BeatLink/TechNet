#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash gum


gum style \
	--foreground "#00ACFF" --border-foreground "#00ACFF" --border thick \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'TechNet Updater' '' 'This scripts automatically updates the selected Host from this flake'


gum style --foreground "#00ACFF" "Select the Host to Update"
HOST=$(gum choose "Ragnarok" "Heimdall" "Odin")
HOST_LOWERCASE=${HOST,,}
gum style --foreground "#00ACFF" "$HOST" ""


gum style --foreground "#00ACFF" 'Do you wish to test the generation or switch?' 
ACTION=$(gum choose "Test" "Switch")
ACTION_LOWERCASE=${ACTION,,}
gum style --foreground "#00ACFF" "$ACTION" ""

FLAKEDIR=$(cd "$(dirname "$0")"; pwd);
PARAMS=(
    --flake "$FLAKEDIR#$HOST"
    --build-host "beatlink@$HOST_LOWERCASE.technet"
    --target-host "beatlink@$HOST_LOWERCASE.technet"
    --no-reexec
    --sudo
    --ask-sudo-password
)
FINAL_COMMAND="nixos-rebuild ${PARAMS[@]} $ACTION_LOWERCASE"

gum confirm && \
    gum style --foreground "#00ACFF" "Beginning NixOS $ACTION..." "" && \
    gum style --foreground "#00ACFF" "Running $FINAL_COMMAND" "" && \
    bash -c "$FINAL_COMMAND"
