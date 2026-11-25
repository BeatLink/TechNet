# Matrix ##############################################################################################################################################
#
# A private Matrix homeserver for the TechNet, reachable only over WireGuard, with bridges that bring WhatsApp, Discord, Facebook Messenger and
# Instagram chats into it as ordinary rooms. Federation is off: the only users on it are the account in secrets/2-server/matrix.yaml and the
# bridges' puppets.
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

    # Every account on this server may use the bridges fully, which keeps the account's name out of the repository
    bridge_permissions."${server_name}" = "admin";

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
                settings = {
                    homeserver.address = synapse_address;
                    appservice.hostname = "127.0.0.1";
                    bridge.permissions = bridge_permissions;

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
                settings = {
                    homeserver = {
                        address = synapse_address;
                        domain = server_name;
                    };
                    appservice = {
                        address = "http://127.0.0.1:29334";
                        hostname = "127.0.0.1";
                    };
                    bridge.permissions = bridge_permissions;
                };
            };

            services.mautrix-meta.instances = lib.genAttrs [ "facebook" "instagram" ] (_: {
                enable = true;
                settings = {
                    homeserver = {
                        address = synapse_address;
                        domain = server_name;
                    };
                    appservice.hostname = "127.0.0.1";
                    bridge.permissions = bridge_permissions;

                    # A short history per chat and no queue paging further back, so the bridge fetches about as much as the app does
                    backfill = {
                        enabled = true;
                        max_initial_messages = 20;
                        queue.enabled = false;
                    };
                };
            });

            environment.persistence."/Storage/Services/Matrix".directories = [
                (persisted_state "mautrix-whatsapp" "mautrix-whatsapp" "/var/lib/mautrix-whatsapp")
                (persisted_state "mautrix-discord" "mautrix-discord" "/var/lib/mautrix-discord")
                (persisted_state "mautrix-meta-facebook" "mautrix-meta" "/var/lib/mautrix-meta-facebook")
                (persisted_state "mautrix-meta-instagram" "mautrix-meta" "/var/lib/mautrix-meta-instagram")
            ];
        }
    ];
}
