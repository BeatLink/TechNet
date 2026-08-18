# Valent ############################################################################################################################################
#
# KDE Connect implementation pairing the phone and the laptop, on the port range the protocol requires.
#
# Started by its own XDG autostart entry, so there is no unit here: one declared alongside it raced the autostarted copy for
# ca.andyholmes.Valent, lost, and was restarted 4819 times in a night, holding a third of a core and 10C the whole time.
#

{ config, ... }:
{
    networking.firewall = rec {
        allowedTCPPortRanges = [
            {
                from = 1714;
                to = 1764;
            }
        ];
        allowedUDPPortRanges = allowedTCPPortRanges;
    };
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            # Set here rather than in the dconf export, which is one file for every host and named whichever machine it was exported from.
            dconf.settings."ca/andyholmes/valent".name = config.networking.hostName;

            home = {
                packages = [ pkgs.valent ];
                persistence."/Storage/Apps/TechNet/Valent" = {
                    directories = [
                        ".cache/valent"
                        ".config/valent"
                    ];

                };

            };
        };
}
