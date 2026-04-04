{ pkgs, ... }:

{
    # Blanks screen after 1 min and turns it off after 2 min.
    # Any keypress will turn it back on.

    systemd.services.screen-off = {
        description = "Blank screen after 1 min and turn it off after 2 min. Any keypress will turn it back on.";
        after = [ "ssh.service" ];
        wantedBy = [ "local.target" ];

        serviceConfig = {
            Type = "oneshot";
            Environment = "TERM=linux";
            StandardOutput = "tty";
            TTYPath = "/dev/console";
            ExecStart = "${pkgs.kbd}/bin/setterm --blank 1 --powerdown 2";
        };
    };
}
