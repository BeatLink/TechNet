# Names for the services a host runs itself.
#
# `technet.vhosts.syncthing.port = 8384` on Thor gives syncthing.thor.lan,
# served by nginx on Thor and proxied to loopback.
#
# Deliberately local. Heimdall could proxy these instead, and for a service that
# lives on Heimdall it does -- see 2-server/3-services/networking/nginx-vhosts.nix.
# For a service on the host you are already using, routing through Heimdall
# sends the request out over WireGuard and straight back again, to reach a
# process listening on loopback. This keeps it on loopback.
#
# The names are added to the host's own /etc/hosts, so a host resolves its own
# services with no DNS at all: no pihole, no WireGuard, nothing that can be
# down. Reaching another host's services still needs a record on Heimdall, and
# that is a separate decision -- this module does not assume it.
#
# HTTP only. The wildcard certificate covers .technet, and nothing here is worth
# a second certificate authority for names that never leave the LAN.
{
    config,
    lib,
    ...
}:
let
    cfg = config.technet.vhosts;

    # Host names are capitalised in the flake and lowercase on the wire.
    host = lib.toLower config.networking.hostName;

    domainOf = name: "${name}.${host}.lan";
in
{
    options.technet.vhosts = lib.mkOption {
        default = { };
        description = ''
            Services this host runs, to be given a name and proxied by a local
            nginx. The attribute name becomes the subdomain.
        '';
        example = lib.literalExpression ''
            {
                syncthing.port = 8384;
                grafana = {
                    port = 3000;
                    openFirewall = true;
                };
            }
        '';
        type = lib.types.attrsOf (
            lib.types.submodule {
                options = {
                    port = lib.mkOption {
                        type = lib.types.port;
                        description = "Port the service listens on.";
                    };

                    address = lib.mkOption {
                        type = lib.types.str;
                        default = "127.0.0.1";
                        description = ''
                            Address to proxy to. Loopback unless the service
                            insists on binding elsewhere.
                        '';
                    };

                    websockets = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = ''
                            Whether to pass websocket upgrades through. On by
                            default because most of these are web UIs that use
                            them, and a proxy that silently drops the upgrade
                            fails in a way that looks like the app is broken.
                        '';
                    };

                    openFirewall = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = ''
                            Whether to accept connections from off the host.
                            Off by default: the point of these names is the
                            host reaching its own services, which never leaves
                            loopback and needs no port open.
                        '';
                    };

                    extraConfig = lib.mkOption {
                        type = lib.types.attrs;
                        default = { };
                        description = "Extra nginx virtualHost options.";
                    };
                };
            }
        );
    };

    config = lib.mkIf (cfg != { }) {
        services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedGzipSettings = true;

            virtualHosts = lib.mapAttrs' (
                name: svc:
                lib.nameValuePair (domainOf name) (
                    {
                        locations."/" = {
                            proxyPass = "http://${svc.address}:${toString svc.port}";
                            proxyWebsockets = svc.websockets;
                        };
                    }
                    // svc.extraConfig
                )
            ) cfg;
        };

        # What makes this work without any DNS. Merges with the localhost entry
        # NixOS already declares rather than replacing it.
        networking.hosts."127.0.0.1" = lib.mapAttrsToList (name: _: domainOf name) cfg;

        networking.firewall.allowedTCPPorts = lib.mkIf (
            lib.any (svc: svc.openFirewall) (lib.attrValues cfg)
        ) [ 80 ];
    };
}
