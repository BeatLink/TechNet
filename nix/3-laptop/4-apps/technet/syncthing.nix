# Syncthing
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism.
#
# The device IDs, folder set and the settings that have to agree across peers come from the shared mesh module in 0-common; what is left
# here is Odin-specific -- the user service, the tray applet and where state persists.
#
{ config, inputs, ... }:
{
    sops.secrets.syncthing_cert = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_key = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_gui_password = {
        sopsFile = "${config.technet.secrets.commonPath}/syncthing.yaml";
        owner = "beatlink";
    };
    sops.secrets.syncthing_api_key = {
        sopsFile = "${config.technet.secrets.path}/syncthing.yaml";
        owner = "beatlink";
    };

    syncthing-mesh.self = "Odin";

    # The GUI is reached at syncthing-odin.heimdall.technet, proxied by Heimdall's nginx over WireGuard.
    networking.firewall.interfaces."wireguard0".allowedTCPPorts = [ 8384 ];

    home-manager.users.beatlink =
        { lib, pkgs, ... }:
        {
            home.packages = with pkgs; [
                syncthingtray-minimal
                libxcb
            ];
            # Qt aborts rather than waiting when no platform plugin loads, so this starts on display.target instead of graphical-session.target.
            systemd.user.services.syncthingtray = {
                Unit = {
                    Requires = [ "display.target" ];
                    After = [ "display.target" ];
                };
                Service = {
                    Restart = "on-failure";
                    RestartSec = 5;
                };
                Install.WantedBy = lib.mkForce [ "display.target" ];
            };

            # A user unit, since Syncthing runs only in the session; the sops file's hash restarts it when the key is rotated.
            systemd.user.services.syncthing-api-key = {
                Unit = {
                    Description = "Apply Syncthing's API key from sops";
                    After = [ "syncthing-init.service" ];
                    Wants = [ "syncthing-init.service" ];
                    X-Restart-Triggers = [
                        (builtins.hashFile "sha256" "${config.technet.secrets.path}/syncthing.yaml")
                    ];
                };
                Service = {
                    Type = "oneshot";
                    RuntimeDirectory = "syncthing-api-key";
                    RuntimeDirectoryMode = "0700";
                    ExecStart = "${pkgs.writeShellScript "syncthing-api-key" (
                        config.syncthing-mesh.applyApiKeyScript {
                            config_file = "/home/beatlink/.local/state/syncthing/config.xml";
                            key_file = config.sops.secrets.syncthing_api_key.path;
                        }
                    )}";
                    # The tray keeps its own copy of the key and rewrites its ini on exit, so it is stopped before the copy is replaced.
                    ExecStartPost = "${pkgs.writeShellScript "syncthing-tray-api-key" ''
                        set -euo pipefail
                        ini="$HOME/.config/syncthingtray.ini"
                        [ -f "$ini" ] || exit 0
                        ${pkgs.gawk}/bin/awk 'NR == FNR { key = $0; next } /apiKey=@ByteArray\(.+\)$/ { sub(/=.*/, "=@ByteArray(" key ")") } { print }' \
                            "${config.sops.secrets.syncthing_api_key.path}" "$ini" > "$RUNTIME_DIRECTORY/tray.ini"
                        if ${pkgs.diffutils}/bin/cmp -s "$RUNTIME_DIRECTORY/tray.ini" "$ini"; then
                            exit 0
                        fi
                        tray_was_active=0
                        if systemctl --user is-active --quiet syncthingtray.service; then
                            tray_was_active=1
                        fi
                        systemctl --user stop syncthingtray.service
                        # Written in place, since the ini is a bind-mounted persisted file that rejects a rename over it.
                        cat "$RUNTIME_DIRECTORY/tray.ini" > "$ini"
                        if [ "$tray_was_active" = 1 ]; then
                            systemctl --user start --no-block syncthingtray.service
                        fi
                    ''}";
                };
                Install.WantedBy = [ "default.target" ];
            };

            systemd.user.targets.tray = {
                Unit = {
                    Description = "Home Manager System Tray";
                    Requires = [ "graphical-session-pre.target" ];
                };
            };
            services.syncthing = {
                enable = true;
                tray = {
                    enable = true;
                    command = "syncthingtray --wait";
                };
                cert = config.sops.secrets.syncthing_cert.path;
                key = config.sops.secrets.syncthing_key.path;
                guiAddress = "0.0.0.0:8384";
                guiCredentials = {
                    username = "beatlink";
                    passwordFile = config.sops.secrets.syncthing_gui_password.path;
                };
                overrideDevices = true;
                overrideFolders = true;
                settings = config.syncthing-mesh.settings;
            };
            home = {
                persistence."/Storage/Apps/TechNet/SyncThing" = {
                    directories = [
                        ".local/state/syncthing"
                    ];
                    files = [
                        ".config/syncthingtray.ini"
                    ];

                };
            };
        };
}
