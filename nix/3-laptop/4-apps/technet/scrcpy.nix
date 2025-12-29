{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.file = {
                #".local/share/icons/home-assistant.png".source = ./home-assistant.png;

                ".local/share/applications/scrcpy.desktop".text = ''
                    [Desktop Entry]
                    Name=ScrCpy
                    Exec=${pkgs.scrcpy}/bin/scrcpy --tcpip=10.100.100.5 --render-driver=opengles2
                    Comment=
                    Terminal=false
                    PrefersNonDefaultGPU=false
                    Icon=phone
                    Categories=Network
                    Type=Application
                '';
            };
        };
}
