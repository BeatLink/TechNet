# Tang ###############################################################################################################################################
#
# The tang key server Odin hosts, started and stopped by hand from the panel applet so keys are only served on demand.
#

{ config, lib, pkgs, ... }:
let
    tangCfg = config.technet.tang;
in
{
    # Options ########################################################################################################################################
    options.technet.tang = {
        port = lib.mkOption {
            type = lib.types.port;
            default = 7654;
            description = "Port Odin's tang server listens on.";
        };

        addresses = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
                "10.100.100.2"
                "192.168.0.3"
            ];
            description = ''
                Addresses Odin's tang server is reachable at, in preference order:
                wireguard first, then the LAN address. Both are bound into the clevis
                JWE so an unlock works whether or not the tunnel is up.
            '';
        };

        urls = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            readOnly = true;
            description = "Tang base URLs, derived from addresses and port.";
        };

        server = {
            enable = lib.mkEnableOption "hosting the tang server, started on demand from the panel applet";

            user = lib.mkOption {
                type = lib.types.str;
                default = "beatlink";
                description = "User the polkit rule lets start and stop tangd.socket.";
            };

            persistenceRoot = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                    Impermanence root for tang's key material, for when the keys are
                    generated on the host rather than supplied by sops.

                    Leave null when sopsFile is set: the keys are then reinstalled from
                    sops on every boot, so the state directory does not need to survive
                    a reboot and persisting it only creates a second place to lose them.
                '';
            };

            sopsFile = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = ''
                    sops file holding tang_key_1 / tang_key_2 (the raw JWK contents) and
                    their matching tang_key_N_thumbprint values. When set, the keys are
                    installed into tang's state directory at boot instead of being
                    generated on first start.

                    These JWKs are tang's identity. Anything that can read them can
                    impersonate the server to any host holding a matching JWE, so the
                    file must not be readable beyond this host and the operator.
                '';
            };

            keyCount = lib.mkOption {
                type = lib.types.int;
                default = 2;
                description = "How many tang_key_N entries sopsFile provides.";
            };
        };
    };

    config = lib.mkMerge [

        # URLs #######################################################################################################################################
        # Derived on every host, not just the server, because the clevis JWEs on the others are bound to these addresses.
        {
            technet.tang.urls = map (addr: "http://${addr}:${toString tangCfg.port}") tangCfg.addresses;
        }


        # Server #####################################################################################################################################
        (lib.mkIf tangCfg.server.enable {
            services.tang = {
                enable = true;
                ipAddressAllow = [
                    "10.100.100.0/24"
                    "192.168.0.0/24"
                ];
                listenStream = [ "0.0.0.0:${toString tangCfg.port}" ];
            };

            networking.firewall.allowedTCPPorts = [ tangCfg.port ];

            environment.persistence = lib.mkIf (tangCfg.server.persistenceRoot != null) {
                ${tangCfg.server.persistenceRoot} = {
                    directories = [
                        {
                            directory = "/var/lib/private/tang";
                            mode = "0700";
                        }
                    ];
                };
            };

            systemd.sockets.tangd = {
                wantedBy = lib.mkForce [ ]; # Started from the panel applet alone, never by a boot target
                unitConfig = lib.mkIf (tangCfg.server.persistenceRoot != null) {
                    RequiresMountsFor = "/var/lib/private/tang";
                };
            };

            systemd.services."tangd@".unitConfig = {
                ConditionDirectoryNotEmpty = "/var/lib/private/tang";
            }
            // lib.optionalAttrs (tangCfg.server.persistenceRoot != null) {
                RequiresMountsFor = "/var/lib/private/tang";
            };

            sops.secrets = lib.mkIf (tangCfg.server.sopsFile != null) (
                lib.listToAttrs (
                    map (i: {
                        name = "tang_key_${toString i}";
                        value = {
                            sopsFile = tangCfg.server.sopsFile;
                            mode = "0400";
                        };
                    }) (lib.range 1 tangCfg.server.keyCount)
                )
            );

            systemd.services.tang-install-keys = lib.mkIf (tangCfg.server.sopsFile != null) {
                description = "Install tang keys from sops into the tang state directory";
                wantedBy = [ "multi-user.target" ];
                after = lib.optional (tangCfg.server.persistenceRoot != null) "var-lib-private-tang.mount";
                unitConfig = lib.mkIf (tangCfg.server.persistenceRoot != null) {
                    RequiresMountsFor = "/var/lib/private/tang";
                };
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                };
                script = ''
                    set -eu
                    dir=/var/lib/private/tang
                    install -d -m 0700 "$dir"

                    ${lib.concatMapStringsSep "\n" (i: ''
                        src="${config.sops.secrets."tang_key_${toString i}".path}"
                        if [ ! -r "$src" ]; then
                            echo "tang-install-keys: $src missing, skipping" >&2
                        else
                            thumb="$(${pkgs.jose}/bin/jose jwk thp -i "$src")"
                            dest="$dir/$thumb.jwk"
                            if [ -e "$dest" ] && ${pkgs.diffutils}/bin/cmp -s "$src" "$dest"; then
                                echo "tang-install-keys: $thumb.jwk already current"
                            else
                                install -m 0440 "$src" "$dest"
                                echo "tang-install-keys: installed $thumb.jwk"
                            fi
                        fi
                    '') (lib.range 1 tangCfg.server.keyCount)}

                    chown -R nobody:nogroup "$dir" 2>/dev/null || true
                    chmod 0700 "$dir"
                '';
            };

            security.polkit.extraConfig = ''
                polkit.addRule(function(action, subject) {
                    if (action.id == "org.freedesktop.systemd1.manage-units" &&
                        action.lookup("unit") == "tangd.socket" &&
                        subject.user == "${tangCfg.server.user}" &&
                        subject.local && subject.active) {
                        return polkit.Result.YES;
                    }
                });
            '';
        })
    ];
}
