# VLC ################################################################################################################################################
#
# Media player. Hardware decoding is forced off until the session renders on the same GPU that VA-API decodes on, or every video plays back green.
#

{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    (pkgs.symlinkJoin {
                        name = "vlc";
                        paths = [ pkgs.vlc ];
                        nativeBuildInputs = [ pkgs.makeWrapper ];
                        postBuild = ''
                            wrapProgram $out/bin/vlc --add-flags "--avcodec-hw=none"
                            entry=$out/share/applications/vlc.desktop
                            source=$(readlink -f $entry)
                            rm $entry
                            substitute $source $entry --replace-fail ${pkgs.vlc}/bin/vlc $out/bin/vlc
                        '';
                    })
                ];
                persistence."/Storage/Apps/Fun/VLC" = {
                    directories = [
                        ".cache/vlc"
                        ".config/vlc"
                        ".local/share/vlc"
                    ];
                };
            };
        };
}
