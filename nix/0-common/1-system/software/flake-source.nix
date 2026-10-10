# Flake Source #######################################################################################################################################
#
# Which flake the fleet deploys from. Heimdall's Vigil builds and activates every host's closure from it, and each agent's sudo rules name it.
#
{ lib, ... }:
{
    options.technet.flake = lib.mkOption {
        type = lib.types.str;
        default = "github:BeatLink/TechNet";
        description = ''
            Flake reference every host is deployed from.

            Heimdall's Vigil deployment monitors evaluate
            `<flake>#nixosConfigurations.<host>` and switch each host to the
            result, so one value decides what the whole fleet runs. The agents'
            sudo rules are written against it too, which is why it is an option
            rather than a literal repeated in both places.

            The published flake rather than a local checkout: a host has no copy
            of the working tree, and a deploy has to be reproducible from what
            was pushed.
        '';
    };
}
