{pkgs, ...}:{
    services.xserver.excludePackages = [ pkgs.xterm ];
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ tilix ];
            persistence."/Storage/Apps/Tools/Tilix" = {
                directories = [
                ];
                allowOther = true;
            };
            /*file = {
                ".config/autostart/guake.desktop".source = "${pkgs.guake}/share/applications/guake.desktop";
            };*/
        };
        dconf.settings."org/cinnamon/desktop/applications/terminal" = {
            "exec" = "tilix";
            "exec-args" = "";
        };
    };
}

