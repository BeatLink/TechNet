# Lid Switch Handling
#
# Hyprland does nothing when the lid closes, so the internal panel stays enabled: the pointer wanders onto a
# screen nobody can see and new windows open there. logind cannot fix it either — HandleLidSwitch is set to
# "ignore" in ../../8-display.nix so that closing the lid at the LightDM greeter does not suspend the machine.
#
# The Cinnamon configuration being reproduced (settings-daemon/plugins/power):
#   lid-close-ac-action        blank
#   lid-close-battery-action   suspend
#
# Cinnamon has no docked case because it never disables a panel, so that branch is this module's own: with an
# external monitor attached, closing the lid only turns the internal one off and everything moves across.
#

{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            hypr-lid = final.writeShellApplication {
                name = "hypr-lid";
                runtimeInputs = with final; [
                    hyprland
                    jq
                    systemd
                    coreutils
                    gnugrep
                ];
                text = ''
                    # The internal panel is whichever monitor is on the embedded DisplayPort. `monitors all`
                    # rather than `monitors`, because a disabled monitor is missing from the latter.
                    internal=$(hyprctl -j monitors all | jq -r '[.[] | select(.name | startswith("eDP")) | .name] | first // empty')
                    [ -n "$internal" ] || exit 0

                    externals=$(hyprctl -j monitors | jq --arg internal "$internal" '[.[] | select(.name != $internal)] | length')

                    on_mains() {
                        for supply in /sys/class/power_supply/*; do
                            if [ "$(cat "$supply/type" 2>/dev/null)" = "Mains" ] &&
                               [ "$(cat "$supply/online" 2>/dev/null)" = "1" ]; then
                                return 0
                            fi
                        done
                        return 1
                    }

                    case "''${1:-}" in
                        close)
                            if [ "$externals" -gt 0 ]; then
                                # Disabling the last monitor leaves Hyprland with nowhere to draw, so this
                                # branch is only safe while something else is attached.
                                hyprctl keyword monitor "$internal, disable"
                            elif on_mains; then
                                loginctl lock-session
                                hyprctl dispatch dpms off
                            else
                                systemctl suspend
                            fi
                            ;;
                        open)
                            hyprctl keyword monitor "$internal, preferred, auto, 1"
                            hyprctl dispatch dpms on
                            ;;
                        init)
                            # A switch bind only fires on a change, so a session started with the lid already
                            # shut would come up with the internal panel on.
                            if [ "$externals" -gt 0 ] && grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null; then
                                hyprctl keyword monitor "$internal, disable"
                            fi
                            ;;
                    esac
                '';
            };
        })
    ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            wayland.windowManager.hyprland.settings = {
                # bindl so the binding still works while the session is locked, which is where a closing lid
                # usually lands. "on" is the closed position of the switch.
                bindl = [
                    ", switch:on:Lid Switch, exec, ${pkgs.hypr-lid}/bin/hypr-lid close"
                    ", switch:off:Lid Switch, exec, ${pkgs.hypr-lid}/bin/hypr-lid open"
                ];
                exec-once = [ "${pkgs.hypr-lid}/bin/hypr-lid init" ];
            };
        };
}
