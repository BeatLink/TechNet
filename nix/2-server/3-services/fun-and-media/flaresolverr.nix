# FlareSolverr #######################################################################################################################################
#
# Headless browser proxy that solves the Cloudflare challenges some of Jackett's indexers sit behind.
# Jackett calls it per request, so nothing here is useful on its own -- jackett.nix is the only consumer.
#

{
    config,
    pkgs,
    lib,
    ...
}:
{
    config = lib.mkMerge [

        # Proxy ######################################################################################################################################
        {
            services.flaresolverr = {
                enable = true;
                port = 8191;
            };

            systemd.services.flaresolverr.environment.HOST = "127.0.0.1"; # Upstream binds 0.0.0.0, reachable over WireGuard if the firewall ever opens
        }

        # Jackett wiring #############################################################################################################################
        {
            systemd.services.jackett.serviceConfig.ExecStartPre = [
                (lib.getExe (
                    pkgs.writeShellApplication {
                        name = "jackett-set-flaresolverr-url";
                        runtimeInputs = [
                            pkgs.jq
                            pkgs.coreutils
                        ];
                        text = ''
                            conf='${config.services.jackett.dataDir}/ServerConfig.json'
                            [ -f "$conf" ] || exit 0 # Jackett writes it on first run, after this point

                            jq --arg url 'http://127.0.0.1:${toString config.services.flaresolverr.port}' \
                                '.FlareSolverrUrl = $url' "$conf" > "$conf.new"
                            mv -f "$conf.new" "$conf"
                        '';
                    }
                ))
            ];

            systemd.services.jackett.after = [ "flaresolverr.service" ];
        }
    ];
}
