{
    config,
    lib,
    pkgs,
    ...
}:
{
    environment.systemPackages = with pkgs; [ variety ];
    home-manager.users.beatlink =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            # Cinnamon's lock screen reuses the desktop background and exposes no key aiming it elsewhere
            setLockScreen = pkgs.writeShellScript "variety-set-lock-screen" ''
                exit 0
            '';
            lockScreen = "${config.home.homeDirectory}/.config/variety/scripts/set_lock_screen";
        in
        {
            home = {
                # Variety chmods this folder at startup, so the script has to be a writable copy rather than a store symlink
                activation.varietySetLockScreen = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
                    run rm -f ${lib.escapeShellArg lockScreen}
                    run install -Dm755 ${setLockScreen} ${lib.escapeShellArg lockScreen}
                '';
                persistence."/Storage/Apps/System/Variety" = {
                    directories = [
                        ".config/variety"
                    ];

                };
            };

            # A unit rather than an autostart .desktop, so its fetching and scaling run niced in a cgroup of their own.
            systemd.user.services.variety = {
                Unit = {
                    Description = "Variety wallpaper changer";
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "display.target" ];
                    After = [ "display.target" ];
                };
                Service = {
                    ExecStart = "${pkgs.variety}/bin/variety";
                    Restart = "on-failure";
                    RestartSec = 5;
                    Nice = 10;
                };
                Install.WantedBy = [ "display.target" ];
            };
        };
}
