{ config, lib, pkgs, ... }:
let
    cfg = config.technet.tang;

    gate = pkgs.writeShellScript "tang-session-gate" ''
        set -u

        SYSTEMCTL=${pkgs.systemd}/bin/systemctl
        GDBUS=${pkgs.glib}/bin/gdbus

        start_tang() {
            $SYSTEMCTL start tangd.socket 2>/dev/null || true
        }

        stop_tang() {
            $SYSTEMCTL stop tangd.socket 2>/dev/null || true
        }

        apply() {
            case "$1" in
                true)  echo "tang-gate: session locked, stopping tang"; stop_tang ;;
                false) echo "tang-gate: session unlocked, starting tang"; start_tang ;;
            esac
        }

        active="$($GDBUS call --session \
            --dest ${cfg.server.screensaver.dbusName} \
            --object-path ${cfg.server.screensaver.objectPath} \
            --method ${cfg.server.screensaver.dbusName}.GetActive 2>/dev/null)"
        case "$active" in
            *true*)  apply true ;;
            *false*) apply false ;;
            *)       echo "tang-gate: screensaver not reachable, failing closed"; stop_tang ;;
        esac

        $GDBUS monitor --session \
            --dest ${cfg.server.screensaver.dbusName} \
            --object-path ${cfg.server.screensaver.objectPath} 2>/dev/null |
        while read -r line; do
            case "$line" in
                *ActiveChanged*true*)  apply true ;;
                *ActiveChanged*false*) apply false ;;
            esac
        done

        echo "tang-gate: monitor exited, failing closed"
        stop_tang
        exit 1
    '';
in
{
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
            enable = lib.mkEnableOption "hosting the tang server, gated on an unlocked desktop session";

            user = lib.mkOption {
                type = lib.types.str;
                default = "beatlink";
                description = "User whose desktop session gates the tang server.";
            };

            persistenceRoot = lib.mkOption {
                type = lib.types.str;
                description = ''
                    Impermanence root for tang's key material. The keys under
                    /var/lib/private/tang ARE the escrow: lose them and every JWE
                    bound to them becomes undecryptable, so this must be persistent.
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

            screensaver = {
                dbusName = lib.mkOption {
                    type = lib.types.str;
                    description = "D-Bus name of the screensaver to watch, e.g. org.cinnamon.ScreenSaver.";
                };

                objectPath = lib.mkOption {
                    type = lib.types.str;
                    description = "D-Bus object path of the screensaver to watch.";
                };
            };
        };
    };

    config = lib.mkMerge [
        {
            technet.tang.urls = map (addr: "http://${addr}:${toString cfg.port}") cfg.addresses;
        }

        (lib.mkIf cfg.server.enable {
            services.tang = {
                enable = true;
                ipAddressAllow = [
                    "10.100.100.0/24"
                    "192.168.0.0/24"
                ];
                listenStream = [ "0.0.0.0:${toString cfg.port}" ];
            };

            networking.firewall.allowedTCPPorts = [ cfg.port ];

            environment.persistence.${cfg.server.persistenceRoot} = {
                directories = [
                    {
                        directory = "/var/lib/private/tang";
                        mode = "0700";
                    }
                ];
            };

            systemd.sockets.tangd = {
                wantedBy = lib.mkForce [ ];
                unitConfig.RequiresMountsFor = "/var/lib/private/tang";
            };

            systemd.services."tangd@".unitConfig = {
                RequiresMountsFor = "/var/lib/private/tang";
                ConditionDirectoryNotEmpty = "/var/lib/private/tang";
            };

            sops.secrets = lib.mkIf (cfg.server.sopsFile != null) (
                lib.listToAttrs (
                    map (i: {
                        name = "tang_key_${toString i}";
                        value = {
                            sopsFile = cfg.server.sopsFile;
                            mode = "0400";
                        };
                    }) (lib.range 1 cfg.server.keyCount)
                )
            );

            systemd.services.tang-install-keys = lib.mkIf (cfg.server.sopsFile != null) {
                description = "Install tang keys from sops into the tang state directory";
                wantedBy = [ "sockets.target" ];
                before = [ "tangd.socket" ];
                after = [ "var-lib-private-tang.mount" ];
                unitConfig.RequiresMountsFor = "/var/lib/private/tang";
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
                            if [ -e "$dest" ] && cmp -s "$src" "$dest"; then
                                echo "tang-install-keys: $thumb.jwk already current"
                            else
                                install -m 0440 "$src" "$dest"
                                echo "tang-install-keys: installed $thumb.jwk"
                            fi
                        fi
                    '') (lib.range 1 cfg.server.keyCount)}

                    chown -R nobody:nogroup "$dir" 2>/dev/null || true
                    chmod 0700 "$dir"
                '';
            };

            security.polkit.extraConfig = ''
                polkit.addRule(function(action, subject) {
                    if (action.id == "org.freedesktop.systemd1.manage-units" &&
                        action.lookup("unit") == "tangd.socket" &&
                        subject.user == "${cfg.server.user}" &&
                        subject.local && subject.active) {
                        return polkit.Result.YES;
                    }
                });
            '';

            systemd.user.services.tang-session-gate = {
                description = "Serve tang only while the desktop session is unlocked";
                wantedBy = [ "graphical-session.target" ];
                partOf = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];
                serviceConfig = {
                    Type = "simple";
                    ExecStart = "${gate}";
                    ExecStopPost = "${pkgs.systemd}/bin/systemctl stop tangd.socket";
                    Restart = "always";
                    RestartSec = 2;
                };
            };
        })
    ];
}
