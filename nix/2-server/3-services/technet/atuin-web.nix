# Atuin Web ##########################################################################################################################################
#
# Browser UI over the shell history atuin.nix collects, for searching it without a terminal.
# Read-only, and it holds no account of its own: a visitor signs in with the same atuin credentials the hosts use.
#

{
    config,
    inputs,
    lib,
    ...
}:
{
    imports = [ inputs.atuin-web.nixosModules.default ];

    config = lib.mkMerge [

        # Web UI #####################################################################################################################################
        {
            nixpkgs.overlays = [ inputs.atuin-web.overlays.default ];

            services.atuin-web = {
                enable = true;
                host = "127.0.0.1";
                port = 9411;
                atuinServerUrl = "http://127.0.0.1:${toString config.services.atuin.port}";
                secureCookies = true; # The vhost is HTTPS-only, and without this the session cookie may travel in clear
            };
        }

        # Reverse Proxy ##############################################################################################################################
        {
            nginx-vhosts.atuin-web = {
                domain = "atuin-web.heimdall.technet";
                port = config.services.atuin-web.port;
            };
        }
    ];
}
