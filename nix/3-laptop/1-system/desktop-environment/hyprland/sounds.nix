# Desktop Event Sounds
#
# Cinnamon plays a sound file on window and session events, configured under org/cinnamon/sounds. Hyprland has no
# equivalent, so this module reproduces it in two parts:
#
#   Window events  - a daemon reads Hyprland's IPC event socket and plays the matching file as events arrive
#   Session events - systemd user units play the login sound on start and the logout sound on stop
#
# The file paths are the ones from the Cinnamon config. They live on /Storage rather than in the nix store, so
# they are read at runtime rather than being copied in at build time. If a file is missing the player simply
# fails and the daemon carries on, so a missing sound never breaks the session.
#
# Cinnamon events with no Hyprland IPC equivalent are not reproduced:
#   plug / unplug  - these are udev level device events rather than compositor events
#   switch         - Cinnamon's workspace switch sound, Hyprland emits workspace events but firing a sound on
#                    every workspace change is noisy with five workspaces where Cinnamon had one
#   tile           - Hyprland has no distinct tile event, windows are tiled on open by the layout
#

{ pkgs, ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            # Reads the Hyprland event socket and plays a sound per event. The socket emits one
            # "eventname>>data" line per event, so the case statement matches on the event name prefix.
            #
            # Sounds are played detached with the player backgrounded, so a slow or failing playback never
            # blocks reading the next event off the socket.
            hypr-event-sounds = final.writeShellApplication {
                name = "hypr-event-sounds";
                runtimeInputs = with final; [
                    socat
                    pulseaudio
                ];
                text = ''
                    sounds="/Storage/Files/Sounds/Interface Sounds/Orwell"

                    open="$sounds/system_data_chunk_window_open-sharedassets1.assets-117.wav"
                    close="$sounds/system_data_chunk_window_close-sharedassets1.assets-132.wav"

                    play() {
                        [ -f "$1" ] || return 0
                        paplay "$1" >/dev/null 2>&1 &
                    }

                    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

                    socat -U - "UNIX-CONNECT:$socket" | while read -r event; do
                        case "$event" in
                            # map-file and maximize-file are the same sound as window open in the Cinnamon
                            # config, and minimize-file and unmaximize-file match window close.
                            openwindow\>*)     play "$open" ;;
                            closewindow\>*)    play "$close" ;;
                            fullscreen\>\>1)   play "$open" ;;
                            fullscreen\>\>0)   play "$close" ;;
                        esac
                    done
                '';
            };
        })
    ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            systemd.user.services = {
                # Window event sounds, matching org/cinnamon/sounds map/close/maximize/minimize/unmaximize
                hypr-event-sounds = {
                    Unit = {
                        Description = "Desktop event sounds for Hyprland";
                        PartOf = [ "graphical-session.target" ];
                        After = [ "graphical-session.target" ];
                    };
                    Service = {
                        ExecStart = "${pkgs.hypr-event-sounds}/bin/hypr-event-sounds";
                        Restart = "on-failure";
                        RestartSec = 2;
                    };
                    Install.WantedBy = [ "graphical-session.target" ];
                };

                # Session sounds, matching org/cinnamon/sounds login-file and logout-file. RemainAfterExit makes
                # the unit stay active after the login sound finishes so that ExecStop fires on session teardown.
                hypr-session-sounds = {
                    Unit = {
                        Description = "Login and logout sounds for Hyprland";
                        PartOf = [ "graphical-session.target" ];
                        After = [ "graphical-session.target" ];
                    };
                    Service = {
                        Type = "oneshot";
                        RemainAfterExit = true;
                        ExecStart = ''
                            ${pkgs.pulseaudio}/bin/paplay "/Storage/Files/Sounds/Interface Sounds/Need to Know/CODEX/SignInOut/Zinger Login.ogg"
                        '';
                        ExecStop = ''
                            ${pkgs.pulseaudio}/bin/paplay "/Storage/Files/Sounds/Interface Sounds/Need to Know/CODEX/SignInOut/Fixed Logout_001.wav"
                        '';
                    };
                    Install.WantedBy = [ "graphical-session.target" ];
                };
            };
        };
}
