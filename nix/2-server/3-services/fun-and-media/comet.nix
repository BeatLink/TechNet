# Comet ##############################################################################################################################################
#
# Stremio addon that searches Jackett for a title and hands Stremio the torrents to stream directly, with no debrid service.
# Pairs with stremio.nix, whose streaming server plays what this finds.
#

{
    config,
    inputs,
    lib,
    pkgs,
    ...
}:
let
    jackettConfig = "${config.services.jackett.dataDir}/ServerConfig.json";
in
{
    imports = [ inputs.comet.nixosModules.default ];

    config = lib.mkMerge [

        # Addon ######################################################################################################################################
        {
            nixpkgs.overlays = [ inputs.comet.overlays.default ];

            services.comet = {
                enable = true;
                port = 9119;
                database.createLocally = true;
                settings = {
                    PUBLIC_BASE_URL = "https://comet.heimdall.technet";
                    SCRAPE_JACKETT = "live";
                    JACKETT_URL = "http://127.0.0.1:${toString config.services.jackett.port}";
                };
            };
        }

        # Jackett wiring #############################################################################################################################
        {
            systemd.services.comet = {
                after = [ "jackett.service" ];
                wants = [ "jackett.service" ];

                serviceConfig = {
                    RuntimeDirectory = "comet";
                    EnvironmentFile = [ "-/run/comet/env" ]; # The dash lets the ExecStartPre below run before the file exists
                    ExecStartPre = [
                        (
                            "+"
                            + lib.getExe (
                                pkgs.writeShellApplication {
                                    name = "comet-read-jackett-api-key";
                                    runtimeInputs = [ pkgs.jq ];
                                    text = ''
                                        umask 077
                                        key=$(jq -er '.APIKey' '${jackettConfig}')
                                        printf 'JACKETT_API_KEY=%s\n' "$key" > /run/comet/env
                                    '';
                                }
                            )
                        )
                    ];
                };
            };
        }

        # Reverse Proxy ##############################################################################################################################
        {
            nginx-vhosts.comet = {
                domain = "comet.heimdall.technet";
                port = config.services.comet.port;
            };
        }
    ];
}
