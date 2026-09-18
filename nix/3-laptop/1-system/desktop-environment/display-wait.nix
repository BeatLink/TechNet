# Display Wait #######################################################################################################################################
#
# Cinnamon imports DISPLAY into the user manager only after graphical-session.target is already reached, so a unit installed into
# that target can start with no display and die. This is that session's network-online.target: the service blocks until the display
# answers, and display.target is the milestone graphical units install into instead.
#
{ pkgs, ... }:
let
    # Either session type counts, and the display has to answer rather than the variable merely be set.
    displayWait = pkgs.writeShellScript "display-wait" ''
        set -u
        while :; do
            unset DISPLAY WAYLAND_DISPLAY XAUTHORITY
            eval "$(${pkgs.systemd}/bin/systemctl --user show-environment |
                ${pkgs.gnugrep}/bin/grep -E '^(DISPLAY|WAYLAND_DISPLAY|XAUTHORITY)=')"

            if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
                case "$WAYLAND_DISPLAY" in
                    /*) socket="$WAYLAND_DISPLAY" ;;
                    *) socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ;;
                esac
                [ -S "$socket" ] && exit 0
            fi

            if [ -n "''${DISPLAY:-}" ]; then
                export DISPLAY XAUTHORITY
                ${pkgs.xorg.xset}/bin/xset q >/dev/null 2>&1 && exit 0
            fi

            ${pkgs.coreutils}/bin/sleep 0.25
        done
    '';
in
{
    home-manager.users.beatlink = {
        systemd.user = {
            services.display-wait = {
                Unit = {
                    Description = "Wait for the session display";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                    Before = [ "display.target" ];
                };
                Service = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = "${displayWait}";
                    # A session that never brings a display up fails this rather than spinning for the life of the login.
                    TimeoutStartSec = 60;
                };
                Install.WantedBy = [ "display.target" ];
            };

            targets.display = {
                Unit = {
                    Description = "Session display available";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };
        };
    };
}
