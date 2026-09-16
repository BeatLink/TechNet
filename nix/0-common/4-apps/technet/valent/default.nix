# Valent #############################################################################################################################################
#
# KDE Connect implementation pairing the phone and the laptop, on the port range the protocol requires.
#
# Started by its own XDG autostart entry, so there is no unit here: one declared alongside it raced the autostarted copy for
# ca.andyholmes.Valent, lost, and was restarted 4819 times in a night, holding a third of a core and 10C the whole time.
#
# No dconf export belongs here: it would carry one host's peers and pairing state to all four, so those live beside each host's own module.
#

{ config, lib, ... }:
{
    options.technet.valent.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
            Whether this host runs a Valent of its own.

            False on a host that shows another's instead, which is Thor: its copy
            is Heimdall's over waypipe, and a second one here would answer the
            same protocol on the same network as a separate peer.
        '';
    };

    config = lib.mkIf config.technet.valent.enable {
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
                # Set per host, because a dconf export is one file for every host and carries whichever machine it was exported from.
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
    };
}
