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
            services.postgresql.dataDir = "/Storage/Services/PostgreSQL/${config.services.postgresql.package.psqlSchema}";

            # Its own hand-made dataset with recordsize=16K, so an 8K page write does not rewrite a whole 128K record.
            fileSystems."/Storage/Services/PostgreSQL" = {
                device = "data-pool-Heimdall/storage/postgresql";
                fsType = "zfs";
                options = [
                    "zfsutil"
                    "nofail"
                ];
            };

            systemd.tmpfiles.settings."PostgreSQL" = {
                "/Storage/Services/PostgreSQL".d = {
                    user = "postgres";
                    group = "postgres";
                    mode = "0750";
                };
                "${config.services.postgresql.dataDir}".d = {
                    user = "postgres";
                    group = "postgres";
                    mode = "0750";
                };
            };
        }
    ];
}
