# Atuin ##############################################################################################################################################
#
# End-to-end encrypted shell history for the fleet, so every host searches one history instead of its own.
# The account is registered once by hand, the same one-time-manual-step pattern as Attic's cache; see docs/heimdall.md.
#

{ config, lib, ... }:
{
    config = lib.mkMerge [

        # Sync Server ################################################################################################################################
        {
            services.atuin = {
                enable = true;
                host = "127.0.0.1";
                port = 9410;
                openRegistration = false;
            };

            nginx-vhosts.atuin = {
                domain = "atuin.heimdall.technet";
                port = config.services.atuin.port;
            };
        }

        # Database ###################################################################################################################################
        {
            # The root SSD, not the data pool: this is SQLite-shaped 8K page writes, which a 1M recordsize with copies=2 turns into megabytes each.
            environment.persistence."/persistent".directories = [
                {
                    directory = "/var/lib/postgresql";
                    user = "postgres";
                    group = "postgres";
                    mode = "0750";
                }
            ];
        }
    ];
}
