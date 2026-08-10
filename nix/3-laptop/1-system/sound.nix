{ ... }:
{
    security.rtkit.enable = true;
    services = {
        pulseaudio.enable = false;
        pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            jack.enable = true;
            wireplumber.enable = true;
        };
    };

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ sox ];
                persistence = {
                    "/Storage/Apps/Tools/Sox" = {
                        directories = [ ];

                    };
                    "/Storage/Apps/System/Pipewire" = {
                        directories = [
                            ".local/state/wireplumber"
                        ];

                    };
                };
            };
        };
}
