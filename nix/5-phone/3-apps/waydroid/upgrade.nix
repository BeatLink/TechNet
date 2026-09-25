# Waydroid During Upgrades ###########################################################################################################################
#
# Evaluating the flake takes most of this phone's memory, and Android starved of it lets its watchdog restart system_server over and over. So
# nixos-upgrade stops Android before it starts, holds it down while it runs, and brings back whatever was running once it ends.
#
{ pkgs, ... }:
let
    hold = "/run/waydroid-upgrade-hold";

    # Records what was running into the hold before stopping it, so the restore brings back only that.
    stop = pkgs.writeShellScript "waydroid-upgrade-stop" ''
        export PATH=${pkgs.systemd}/bin:${pkgs.coreutils}/bin:$PATH
        : > ${hold}
        systemctl is-active -q waydroid-container && echo container >> ${hold}

        # A session handed to a waypipe display runs outside the unit, and its own cleanup starts the unit, so it counts as the session running.
        if systemctl --user -M beatlink@ is-active -q waydroid-session || [ -e /run/user/1000/waydroid-remote/pid ]; then
            echo session >> ${hold}
        fi

        systemctl --user -M beatlink@ stop waydroid-session
        systemctl stop waydroid-container
    '';

    # Runs whether the upgrade succeeded or not; a pending reboot brings Android back on its own.
    restore = pkgs.writeShellScript "waydroid-upgrade-restore" ''
        export PATH=${pkgs.systemd}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH
        held=$(cat ${hold} 2>/dev/null)
        rm -f ${hold}
        [ -e /run/systemd/shutdown/scheduled ] && exit 0

        printf '%s\n' "$held" | grep -qx container && systemctl start waydroid-container
        printf '%s\n' "$held" | grep -qx session && systemctl --user -M beatlink@ start --no-block waydroid-session
        exit 0
    '';
in
{
    systemd.services.nixos-upgrade.serviceConfig = {
        ExecStartPre = [ "-${stop}" ];
        ExecStopPost = [ "-${restore}" ];
    };

    # Without these, the switch starting multi-user.target or a remote session handing back would bring Android up mid-run.
    systemd.services.waydroid-container.unitConfig.ConditionPathExists = "!${hold}";
    home-manager.users.beatlink.systemd.user.services.waydroid-session.Unit.ConditionPathExists =
        "!${hold}";
}
