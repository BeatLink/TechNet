# Rebind Clevis
#
# Renews a host's clevis bindings from Odin: the host's disk passphrase is decrypted from secrets/admin with the user's own age key and piped over SSH
# into that host's rebind-clevis, so no host holds a copy of its own passphrase. Tang is started for the run when it is not already serving.
#
{ pkgs, ... }:
{
    # Rebind Clevis ##################################################################################################################################
    environment.systemPackages = [
        (pkgs.writeShellApplication {
            name = "rebind-clevis";
            runtimeInputs = [
                pkgs.openssh
                pkgs.sops
            ];
            text = ''
                set -euo pipefail

                if [ "$#" -eq 0 ]; then
                    echo "Usage: rebind-clevis <Heimdall|Ragnarok|Thor>..." >&2
                    exit 2
                fi

                for host in "$@"; do
                    case "$host" in
                        Heimdall | Ragnarok | Thor) ;;
                        *)
                            echo "rebind-clevis: $host has no clevis bindings; choose from Heimdall, Ragnarok and Thor" >&2
                            exit 2
                            ;;
                    esac
                done

                if [ ! -f .sops.yaml ] || [ ! -f secrets/admin/nixtool.yaml ]; then
                    echo "rebind-clevis: run this from the root of the TechNet checkout" >&2
                    exit 1
                fi

                tang_was_running=true
                if ! systemctl is-active -q tangd.socket; then
                    tang_was_running=false
                    sudo -n systemctl start tangd.socket
                    echo "rebind-clevis: started tang for this run"
                fi

                stop_tang() {
                    if [ "$tang_was_running" = false ]; then
                        sudo -n systemctl stop tangd.socket
                        echo "rebind-clevis: stopped tang again"
                    fi
                }
                trap stop_tang EXIT

                for host in "$@"; do
                    name="''${host,,}"
                    echo "rebind-clevis: rebinding $host"
                    # The passphrase only ever travels down this pipe; sops prints errors, never the value, and a dead SSH session just closes the pipe
                    sops --decrypt --extract "[\"''${name}_encryption_key\"]" secrets/admin/nixtool.yaml \
                        | ssh -o BatchMode=yes "$name.technet" sudo -n env PATH=/run/wrappers/bin:/run/current-system/sw/bin rebind-clevis
                done
            '';
        })
    ];
}
