# Matrix ##############################################################################################################################################
#
# A private Matrix homeserver for the TechNet, reachable only over WireGuard, with bridges that bring WhatsApp and Discord chats into it as
# ordinary rooms. Federation is off: the only users on it are the account in secrets/2-server/matrix.yaml and the bridges' puppets.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    server_name = "matrix.heimdall.technet";
    synapse_port = 8008;
    synapse_address = "http://127.0.0.1:${toString synapse_port}";
    data_directory = "/var/lib/matrix-synapse";
    registration_secret_file = "${data_directory}/registration_shared_secret";
    secrets_file = "${config.technet.secrets.path}/matrix.yaml";
    double_puppet_registration = "${data_directory}/double-puppet-registration.yaml";
    double_puppet_environment = "${data_directory}/double-puppet.env";
    double_puppet_secret = "as_token:$DOUBLE_PUPPET_AS_TOKEN";

    # Every account on this server may use the bridges fully, which keeps the account's name out of the repository
    bridge_permissions."${server_name}" = "admin";

    bridge_units = [
        "mautrix-whatsapp"
        "mautrix-discord"
        "mautrix-discord-registration"
    ];

    persisted_state = user: group: directory: {
        inherit directory user group;
        mode = "0700";
    };
in
{
    config = lib.mkMerge [

        # Homeserver #################################################################################################################################
        {
            services.matrix-synapse = {
                enable = true;
                dataDir = data_directory;
                settings = {
                    inherit server_name;
                    public_baseurl = "https://${server_name}/";

                    listeners = [
                        {
                            port = synapse_port;
                            bind_addresses = [ "127.0.0.1" ];
                            type = "http";
                            tls = false;
                            x_forwarded = true;
                            resources = [
                                {
                                    names = [ "client" ];
                                    compress = true;
                                }
                            ];
                        }
                    ];

                    # An empty allow list turns federation off, and no key servers keeps Synapse from calling out to matrix.org
                    federation_domain_whitelist = [ ];
                    trusted_key_servers = [ ];

                    enable_registration = false;
                    registration_shared_secret_path = registration_secret_file;
                    max_upload_size = "100M";
                };
            };

            # Makes the registration secret on first start, so it never sits in the repository or the nix store
            systemd.services.matrix-synapse.serviceConfig.ExecStartPre = lib.mkBefore [
                "+${pkgs.writeShellScript "matrix-synapse-registration-secret" ''
                    if [ ! -s ${registration_secret_file} ]; then
                        umask 077
                        ${pkgs.openssl}/bin/openssl rand -hex 32 > ${registration_secret_file}
                        chown matrix-synapse:matrix-synapse ${registration_secret_file}
                    fi
                ''}"
            ];

            nginx-vhosts.matrix = {
                domain = server_name;
                port = synapse_port;
                extraConfig.extraConfig = "client_max_body_size 100M;";
            };

            environment.persistence."/Storage/Services/Matrix".directories = [
                (persisted_state "matrix-synapse" "matrix-synapse" data_directory)
            ];
        }

        # Double Puppeting ###########################################################################################################################
        {
            # An app service with no address whose token lets the bridges post as the real account, so messages sent from the phones show as its own
            services.matrix-synapse.settings.app_service_config_files = [ double_puppet_registration ];

            # Makes the token on first start and keeps it on Heimdall; systemd reads the environment file for the bridges as root
            systemd.services.matrix-double-puppet = {
                description = "Create the Matrix double puppeting token";
                requiredBy = [ "matrix-synapse.service" ] ++ map (unit: "${unit}.service") bridge_units;
                before = [ "matrix-synapse.service" ] ++ map (unit: "${unit}.service") bridge_units;
                unitConfig.RequiresMountsFor = [ data_directory ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                };
                script = ''
                    if [ ! -s ${double_puppet_environment} ]; then
                        umask 077
                        token=$(${pkgs.openssl}/bin/openssl rand -hex 32)
                        printf 'DOUBLE_PUPPET_AS_TOKEN=%s\n' "$token" > ${double_puppet_environment}
                        cat > ${double_puppet_registration} <<EOF
                    id: doublepuppet
                    url: null
                    as_token: $token
                    hs_token: $(${pkgs.openssl}/bin/openssl rand -hex 32)
                    sender_localpart: $(${pkgs.openssl}/bin/openssl rand -hex 16)
                    rate_limited: false
                    namespaces:
                      users:
                        - regex: '@.*:${lib.escape [ "." ] server_name}'
                          exclusive: false
                    EOF
                        chown matrix-synapse:matrix-synapse ${double_puppet_registration}
                    fi
                '';
            };
        }

        # Account ####################################################################################################################################
        {
            sops.secrets = lib.genAttrs [ "matrix_username" "matrix_password" ] (_: {
                sopsFile = secrets_file;
                owner = "matrix-synapse";
            });

            # Creates the account from the secrets file when it is missing, and leaves an existing one untouched
            systemd.services.matrix-synapse-account = {
                description = "Create the Matrix account";
                wants = [ "matrix-synapse.service" ];
                after = [ "matrix-synapse.service" ];
                wantedBy = [ "multi-user.target" ];
                # Retries while Synapse is still restarting, as it does once on first start while the bridges write their registrations
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    User = "matrix-synapse";
                    Restart = "on-failure";
                    RestartSec = "1min";
                };
                script = ''
                    username=$(< ${config.sops.secrets.matrix_username.path})
                    if [ "$username" = CHANGEME ]; then
                        echo "secrets/2-server/matrix.yaml still holds placeholders; set matrix_username and matrix_password with sops"
                        exit 1
                    fi
                    ${lib.getExe' config.services.matrix-synapse.package "register_new_matrix_user"} \
                        --config ${config.services.matrix-synapse.configFile} \
                        --user "$username" \
                        --password-file ${config.sops.secrets.matrix_password.path} \
                        --admin \
                        --exists-ok \
                        ${synapse_address}
                '';
            };
        }

        # Database ###################################################################################################################################
        {
            services.postgresql.ensureUsers = [ { name = "matrix-synapse"; } ];

            # Synapse needs a database with C collation, which ensureDatabases cannot make
            systemd.services.matrix-synapse-database = {
                description = "Create the Synapse database";
                requires = [ "postgresql-setup.service" ];
                after = [ "postgresql-setup.service" ];
                requiredBy = [ "matrix-synapse.service" ];
                before = [ "matrix-synapse.service" ];
                path = [ config.services.postgresql.package ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    User = "postgres";
                };
                script = ''
                    if [ -z "$(psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'matrix-synapse'")" ]; then
                        createdb --template=template0 --locale=C --encoding=UTF8 --owner=matrix-synapse matrix-synapse
                    fi
                '';
            };
        }

        # Bridges ####################################################################################################################################
        {
            # The Discord bridge links libolm, which is only used for encrypted rooms and encryption is off on it
            nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

            services.mautrix-whatsapp = {
                enable = true;
                environmentFile = double_puppet_environment;
                settings = {
                    homeserver.address = synapse_address;
                    appservice.hostname = "127.0.0.1";
                    bridge.permissions = bridge_permissions;
                    double_puppet.secrets."${server_name}" = double_puppet_secret;

                    # Takes only the recent history the phone pushes to any new linked device, not the whole archive
                    network.history_sync.request_full_sync = false;
                    backfill = {
                        enabled = true;
                        max_initial_messages = 50;
                    };
                };
            };

            # Its defaults already backfill nothing and bridge no server until asked with `guilds bridge`
            services.mautrix-discord = {
                enable = true;
                environmentFile = double_puppet_environment;
                settings = {
                    homeserver = {
                        address = synapse_address;
                        domain = server_name;
                    };
                    appservice = {
                        address = "http://127.0.0.1:29334";
                        hostname = "127.0.0.1";
                    };
                    bridge = {
                        permissions = bridge_permissions;
                        login_shared_secret_map."${server_name}" = double_puppet_secret;
                    };
                };
            };

            environment.persistence."/Storage/Services/Matrix".directories = [
                (persisted_state "mautrix-whatsapp" "mautrix-whatsapp" "/var/lib/mautrix-whatsapp")
                (persisted_state "mautrix-discord" "mautrix-discord" "/var/lib/mautrix-discord")
            ];
        }
    ];
}
