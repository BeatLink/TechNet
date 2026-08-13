# Attic Binary Cache #################################################################################################################################
#
# Points every host at Heimdall's Attic cache, so a path built on one machine is substituted rather than rebuilt on the rest.
#
# Network-wide rather than opt-in, because the cache holds whatever the fleet builds and answers for anything else without complaint. The cache is
# public, so no token is needed to pull; pushing is a separate credential held only by the services that mirror into it.
#
# A host that cannot reach Heimdall -- off the network, or Heimdall down -- logs a warning per substitution and carries on with the remaining
# substituters, so this stays safe on the laptop and the phone.
#

{ ... }:
{
    nix.settings = {
        extra-substituters = [ "https://attic.heimdall.technet/technet" ];
        extra-trusted-public-keys = [ "technet:jU6BgeS9vVCWnEsIAMqi+Zzs+O7TLBRj64jobErZdVY=" ];
    };
}
