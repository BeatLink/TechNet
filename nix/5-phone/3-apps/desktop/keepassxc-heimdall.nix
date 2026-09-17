# KeePassXC on Heimdall, displayed here over waypipe, on the same database.
#
# It reads a config of its own, seeded by Heimdall's phone-apps module, because there is no tray here
# to hold a window or to get one back.
#
# The session starts it rather than the app grid, because the three integrations it offers are only
# worth having if they are up before the app that wants them: the secret service answers on the
# session's own bus, the browser proxy on a socket Firefox reaches, and the ssh agent on Heimdall
# holds whatever keys the database unlocks. The unit dies with the session and reaps its copy on the
# way out, so the next session's launch is never handed a window whose display is gone.
#
{ pkgs, ... }:
let
    session = "waypipe-session-heimdall-waypipe.service"; # Named after the host key below, which is how waypipe-desktop names its units
in
{
    technet.waypipe.apps.keepassxc-heimdall = {
        title = "KeePassXC (Heimdall)";
        host = "heimdall-waypipe";
        icon = ./keepassxc.png;
        categories = [
            "Utility"
            "Security"
            "Qt"
        ];

        command = [
            "keepassxc"
            "--config"
            "/Storage/PhoneApps/KeePassXC/Thor/keepassxc.ini"
            "/Storage/Files/Documents/SecurityDatabase.kdbx"
        ];

        environment = {
            QT_QPA_PLATFORM = "wayland"; # KeePassXC is Qt, so GDK_BACKEND does nothing for it
            SSH_AUTH_SOCK = "/run/user/1000/ssh-agent"; # beatlink's agent on Heimdall, the one an unlocked database adds its keys to
        };
    };

    home-manager.users.beatlink.systemd.user.services.keepassxc-heimdall = {
        Unit = {
            Description = "KeePassXC, held open in Heimdall's waypipe session";
            BindsTo = [ session ];
            After = [ session ];
        };

        Service = {
            ExecStart = "${pkgs.waypipe-desktop}/bin/waypipe-desktop run keepassxc-heimdall";

            # The session ending is what stops this, and the ssh it runs reports that as 255 rather than dying of the signal
            SuccessExitStatus = "SIGTERM 255";

            # sshd leaves a remote command running when its link drops, and a copy with a dead display would answer the next session's launch
            ExecStopPost = "-${pkgs.openssh}/bin/ssh -o BatchMode=yes heimdall-waypipe pkill -f KeePassXC/Thor/keepassxc.ini";
        };

        Install.WantedBy = [ session ];
    };
}
