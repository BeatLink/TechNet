# Jackettio ##########################################################################################################################################
#
# Stremio addon that searches Jackett for a title and resolves the results into streams through a debrid service.
# Each viewer's debrid account lives in the addon URL built on its /configure page, so nothing here holds one.
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
    imports = [ inputs.jackettio.nixosModules.default ];

    config = lib.mkMerge [

        # Addon ######################################################################################################################################
        {
            nixpkgs.overlays = [ inputs.jackettio.overlays.default ];

            services.jackettio = {
                enable = true;
                port = 9118;
                jackettUrl = "http://127.0.0.1:${toString config.services.jackett.port}";
            };

            environment.persistence."/Storage/Services/Jackettio".directories = [
                "/var/lib/private/jackettio"
            ];

            systemd.tmpfiles.settings."Jackettio" = {
                "/Storage/Services/Jackettio".d = {
                    user = "root";
                    group = "root";
                    mode = "0755";
                };
                "/Storage/Services/Jackettio/.nobackup".f = {
                    user = "root";
                    group = "root";
                    mode = "0644";
                };
            };
        }

        # Jackett wiring #############################################################################################################################
        {
            systemd.services.jackettio = {
                after = [ "jackett.service" ];
                wants = [ "jackett.service" ];

                serviceConfig = {
                    RuntimeDirectory = "jackettio";
                    EnvironmentFile = [ "-/run/jackettio/env" ]; # The dash lets the ExecStartPre below run before the file exists
                    ExecStartPre = [
                        (
                            "+"
                            + lib.getExe (
                                pkgs.writeShellApplication {
                                    name = "jackettio-read-jackett-api-key";
                                    runtimeInputs = [ pkgs.jq ];
                                    text = ''
                                        umask 077
                                        key=$(jq -er '.APIKey' '${jackettConfig}')
                                        printf 'JACKETT_API_KEY=%s\n' "$key" > /run/jackettio/env
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
            nginx-vhosts.jackettio = {
                domain = "jackettio.heimdall.technet";
                port = config.services.jackettio.port;
            };
        }
    ];
}
