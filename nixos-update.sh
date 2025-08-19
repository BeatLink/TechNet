#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash gum



title(){
  gum style --foreground "#00ACFF" --border-foreground "#00ACFF" --border thick --align center --width 200 --margin "1 2" --padding "2 4" "$@"
}

pr() {
  gum style --foreground "#00ACFF" "$@"
}


title 'TechNet Updater' '' 'This scripts automatically updates the selected Host from this flake'


pr "Select the Host to Update"
HOST=$(gum choose "Ragnarok" "Heimdall" "Odin")
HOST_LOWERCASE=${HOST,,}
pr "$HOST" ""


pr 'Do you wish to test the generation or switch?' 
ACTION=$(gum choose "Test" "Switch")
ACTION_LOWERCASE=${ACTION,,}
pr "$ACTION" ""

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
    pr "Beginning NixOS $ACTION..." "" && \
    pr "Running $FINAL_COMMAND" "" && \
    bash -c "$FINAL_COMMAND"
