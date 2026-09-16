{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    (pkgs.symlinkJoin {
                        name = "discord";
                        paths = [ pkgs.discord ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        postBuild = ''
                            wrapProgram $out/bin/Discord --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json # Without this the camera background filter builds its EGL context on the dGPU while the client renders on the iGPU, and the video pipeline hangs
                            ln -sf Discord $out/bin/discord # The packaged lowercase symlink points into the unwrapped store path, so it has to be repointed at the wrapper
                        '';
                    })
                ];
                persistence."/Storage/Apps/Comms/Discord" = {
                    directories = [
                        ".config/discord"
                    ];

                };
            };
        };
}
