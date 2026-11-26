# Mail ###############################################################################################################################################
#
# Moves mail off Gmail and Outlook.com into a Dovecot mailbox on Heimdall. imapsync copies every folder from each account on a timer into one
# shared Inbox, Drafts, Sent and Archive, with the rest under Gmail/ and Outlook/, then deletes
# what it copied from the account once delete_from_source is on. Mail clients read the mailbox over IMAP at mail.heimdall.technet:993, and a
# browser at https://mail.heimdall.technet, on the LAN and over WireGuard; clients send through Heimdall at mail.heimdall.technet:465, which
# relays each message through Gmail or Outlook by its From address.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    mail_directory = "/Storage/Services/Mail";
    oauth_directory = "${mail_directory}/oauth";
    users_file = "/run/dovecot-users/passwd";
    imap_port = 143;
    submission_port = 587;
    relay_maps_directory = "/run/mail-relay";
    secrets_file = "${config.technet.secrets.path}/mail.yaml";
    path_of = name: config.sops.secrets.${name}.path;

    # Every message is deleted from its account once it has been copied here
    delete_from_source = true;

    mail-oauth = pkgs.writers.writePython3Bin "mail-oauth" { flakeIgnore = [ "E501" ]; } (builtins.readFile ./mail-oauth.py);

    # Sends one message from Postfix through Gmail or Outlook, signing in the same way the fetch does
    relay_send = pkgs.writeShellApplication {
        name = "mail-relay-send";
        runtimeInputs = [
            pkgs.coreutils
            pkgs.msmtp
            mail-oauth
        ];
        text = ''
            account=$1
            sender=$2
            shift 2

            case $account in
                gmail)
                    login_file=${path_of "gmail_address"}
                    sign_in=(--host=smtp.gmail.com --port=465 --tls-starttls=off --auth=plain --passwordeval="head -n 1 ${path_of "gmail_app_password"}")
                    ;;
                outlook)
                    login_file=${path_of "outlook_address"}
                    sign_in=(--host=smtp-mail.outlook.com --port=587 --tls-starttls=on --auth=xoauth2 --passwordeval="mail-oauth token ${oauth_directory}/outlook.json --output -")
                    ;;
                *)
                    exit 64
                    ;;
            esac

            status=0
            msmtp "''${sign_in[@]}" --tls=on --tls-trust-file=/etc/ssl/certs/ca-certificates.crt \
                --user="$(< "$login_file")" --from="''${sender:-$(< "$login_file")}" -- "$@" || status=$?

            # A network or sign-in hiccup must not bounce the mail, so every failure but bad input asks Postfix to try again later
            case $status in
                0 | 64 | 65) exit "$status" ;;
                *) exit 75 ;;
            esac
        '';
    };

    # Stops a unit with a clear message while secrets/2-server/mail.yaml still holds the CHANGEME placeholders it ships with
    placeholder_check = names: ''
        for secret_file in ${lib.concatMapStringsSep " " path_of names}; do
            if [ "$(< "$secret_file")" = CHANGEME ]; then
                echo "secrets/2-server/mail.yaml still holds placeholders; fill it in with sops"
                exit 1
            fi
        done
    '';

    # One imapsync run that copies an account into its own top-level folder of the Heimdall mailbox, prefixed by hand since --subfolder2 skips any source folder matching its name
    # main_folders sends the account's main folders into the shared top-level ones instead of its own folder
    fetch_account =
        {
            name,
            description,
            secret_names,
            prepare ? "",
            source_arguments,
            main_folders,
        }:
        {
            systemd.services."mail-fetch-${name}" = {
                inherit description;
                after = [
                    "dovecot.service"
                    "network-online.target"
                ];
                requires = [ "dovecot.service" ];
                wants = [ "network-online.target" ];
                path = [
                    pkgs.imapsync
                    mail-oauth
                ];
                serviceConfig = {
                    Type = "oneshot";
                    User = "vmail";
                    Group = "vmail";
                    RuntimeDirectory = "mail-fetch-${name}";
                    RuntimeDirectoryMode = "0700";
                    Nice = 10;
                };
                script = ''
                    ${placeholder_check ([ "mail_username" "mail_password" ] ++ secret_names)}
                    ${prepare}
                    imapsync \
                        ${lib.trim source_arguments} \
                        ${lib.concatMapStringsSep " " (folder: lib.escapeShellArg "--f1f2=${folder.name}=${folder.value}") (lib.attrsToList main_folders)} \
                        --host2 127.0.0.1 --port2 ${toString imap_port} --nossl2 --notls2 \
                        --user2 "$(< ${path_of "mail_username"})" --passfile2 ${path_of "mail_password"} \
                        --regextrans2 's,^,${description}/,' \
                        --addheader --nolog --tmpdir "$RUNTIME_DIRECTORY" \
                        ${lib.optionalString delete_from_source "--delete1"}
                '';
            };

            systemd.timers."mail-fetch-${name}" = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = "*:0/10";
                    Persistent = true;
                    RandomizedDelaySec = "1m";
                };
            };
        };
in
{
    config = lib.mkMerge [

        # Mailbox ####################################################################################################################################
        {
            sops.secrets =
                lib.genAttrs
                    [
                        "mail_username"
                        "mail_password"
                        "gmail_address"
                        "gmail_app_password"
                        "outlook_address"
                    ]
                    (_: {
                        sopsFile = secrets_file;
                        owner = "vmail";
                        restartUnits = [
                            "dovecot-users.service"
                            "mail-relay-maps.service"
                            "postfix.service"
                        ];
                    });

            services.dovecot2 = {
                enable = true;
                package = pkgs.dovecot;
                settings = {
                    dovecot_config_version = "2.4.0";
                    dovecot_storage_version = "2.4.0";
                    protocols.imap = true;

                    # nginx terminates TLS and hands the connection over on loopback, which Dovecot counts as secure
                    listen = "127.0.0.1";
                    ssl = false;

                    mail_driver = "maildir";
                    mail_home = "${mail_directory}/%{user | username}";
                    mail_path = "~/Maildir";

                    # Lets folder names such as Gmail labels hold a dot, which Maildir otherwise uses between folder levels
                    mailbox_list_storage_escape_char = "%";
                    mail_uid = "vmail";
                    mail_gid = "vmail";

                    # The shared main folders are marked so every mail client lists them first with their usual icons
                    "namespace inbox" = {
                        inbox = true;
                        separator = "/";
                        mailbox = lib.mapAttrsToList (folder: special_use: {
                            _section.name = folder;
                            inherit special_use;
                            auto = "subscribe";
                        }) {
                            Drafts = "\\Drafts";
                            Sent = "\\Sent";
                            Archive = "\\Archive";
                            Trash = "\\Trash";
                        };
                    };

                    "passdb passwd-file".passwd_file_path = users_file;
                    "userdb static" = { };

                    "service imap-login" = {
                        "inet_listener imap".port = imap_port;
                        "inet_listener imaps".port = 0;
                    };
                };
            };

            # Writes the one Dovecot login from the secrets file, with the password hashed
            systemd.services.dovecot-users = {
                description = "Write the Dovecot login";
                before = [ "dovecot.service" ];
                wantedBy = [ "dovecot.service" ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    RuntimeDirectory = "dovecot-users";
                    RuntimeDirectoryMode = "0755";
                };
                script = ''
                    ${placeholder_check [ "mail_username" "mail_password" ]}
                    password_hash=$(${pkgs.mkpasswd}/bin/mkpasswd --method=yescrypt --stdin < ${path_of "mail_password"})
                    umask 027
                    printf '%s:{CRYPT}%s\n' "$(< ${path_of "mail_username"})" "$password_hash" > ${users_file}.new
                    chgrp ${config.services.dovecot2.settings.default_internal_group} ${users_file}.new
                    mv ${users_file}.new ${users_file}
                '';
            };

            systemd.tmpfiles.settings."Mail" = {
                ${mail_directory}.d = {
                    user = "vmail";
                    group = "vmail";
                    mode = "0700";
                };
                ${oauth_directory}.d = {
                    user = "vmail";
                    group = "vmail";
                    mode = "0700";
                };
            };

            environment.systemPackages = [ mail-oauth ];
        }

        # Client Access ##############################################################################################################################
        {
            # 993 and 465 are open on the LAN, where split DNS sends the name at home, and over wireguard0, a trusted interface
            networking.firewall.interfaces.lan0.allowedTCPPorts = [
                993
                465
            ];

            services.nginx.streamConfig = ''
                server {
                    listen 993 ssl;
                    ssl_certificate ${config.sops.secrets.https_certificate.path};
                    ssl_certificate_key ${config.sops.secrets.https_certificate_key.path};
                    proxy_pass 127.0.0.1:${toString imap_port};
                }

                server {
                    listen 465 ssl;
                    ssl_certificate ${config.sops.secrets.https_certificate.path};
                    ssl_certificate_key ${config.sops.secrets.https_certificate_key.path};
                    proxy_pass 127.0.0.1:${toString submission_port};
                }
            '';

            services.pihole-ftl.settings.dns.cnameRecords = [ "mail.heimdall.technet,heimdall.technet" ];
        }

        # Webmail ####################################################################################################################################
        {
            # Roundcube reads the same mailbox over loopback and keeps its settings in the shared Postgres instance
            services.roundcube = {
                enable = true;
                hostName = "mail.heimdall.technet";
                extraConfig = ''
                    $config['imap_host'] = 'localhost:${toString imap_port}';
                    $config['product_name'] = 'Heimdall Mail';
                    $config['smtp_host'] = 'localhost:${toString submission_port}';
                    $config['smtp_user'] = '%u';
                    $config['smtp_pass'] = '%p';
                '';
            };

            services.nginx.virtualHosts."mail.heimdall.technet" = {
                forceSSL = false;
                enableACME = false;
                addSSL = true;
                sslCertificate = config.sops.secrets.https_certificate.path;
                sslCertificateKey = config.sops.secrets.https_certificate_key.path;
            };
        }

        # Sending ####################################################################################################################################
        {
            # Postfix takes mail from clients signed in with the Heimdall login and hands it to Gmail or Outlook by its From address
            services.postfix = {
                enable = true;
                enableSmtp = false;
                setSendmail = false;
                settings.main = {
                    myhostname = "mail.heimdall.technet";
                    mydestination = [ ];
                    inet_interfaces = "loopback-only";
                    sender_dependent_default_transport_maps = "texthash:${relay_maps_directory}/transports";

                    # Bounces have no sender to pick a relay by, so they go back to the Gmail inbox and get fetched from there
                    default_transport = "relay-gmail:";

                    relay_sender_restrictions = [
                        "reject_non_fqdn_sender"
                        "check_sender_access texthash:${relay_maps_directory}/senders"
                        "reject"
                    ];
                };
                settings.master = {
                    "127.0.0.1:${toString submission_port}" = {
                        type = "inet";
                        private = false;
                        chroot = false;
                        command = "smtpd";
                        args = [
                            "-o" "syslog_name=postfix/submission"
                            "-o" "smtpd_sasl_auth_enable=yes"
                            "-o" "smtpd_sasl_type=dovecot"
                            "-o" "smtpd_sasl_path=/run/dovecot2/auth-postfix"
                            "-o" "smtpd_client_restrictions=permit_sasl_authenticated,reject"
                            "-o" "smtpd_sender_restrictions=$relay_sender_restrictions"
                            "-o" "smtpd_relay_restrictions=permit_sasl_authenticated,reject"
                            "-o" "smtpd_recipient_restrictions=permit_sasl_authenticated,reject"
                        ];
                    };
                }
                // lib.genAttrs [ "relay-gmail" "relay-outlook" ] (transport: {
                    privileged = true;
                    chroot = false;
                    command = "pipe";
                    args = [
                        "flags=q"
                        "user=vmail"
                        "argv=${relay_send}/bin/mail-relay-send ${lib.removePrefix "relay-" transport} \${sender} \${recipient}"
                    ];
                });
            };

            # Postfix checks the Heimdall login against Dovecot, through a socket in Dovecot's own directory so neither waits on the other
            services.dovecot2.settings."service auth"."unix_listener auth-postfix" = {
                mode = "0660";
                user = "postfix";
                group = "postfix";
            };

            # Writes which From addresses may send and through which account, straight from the secrets file
            systemd.services.mail-relay-maps = {
                description = "Write the mail relay's sender maps";
                before = [ "postfix.service" ];
                wantedBy = [ "postfix.service" ];
                serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    RuntimeDirectory = "mail-relay";
                    RuntimeDirectoryMode = "0755";
                };
                script = ''
                    umask 022
                    : > ${relay_maps_directory}/senders.new
                    : > ${relay_maps_directory}/transports.new
                    ${lib.concatMapStrings (account: ''
                        if ! grep -qix changeme ${path_of "${account}_address"}; then
                            tr '[:upper:]' '[:lower:]' < ${path_of "${account}_address"} | sed 's/$/ OK/' >> ${relay_maps_directory}/senders.new
                            tr '[:upper:]' '[:lower:]' < ${path_of "${account}_address"} | sed 's/$/ relay-${account}:/' >> ${relay_maps_directory}/transports.new
                        fi
                    '') [ "gmail" "outlook" ]}
                    mv ${relay_maps_directory}/senders.new ${relay_maps_directory}/senders
                    mv ${relay_maps_directory}/transports.new ${relay_maps_directory}/transports
                '';
            };
        }

        # Gmail ######################################################################################################################################
        (fetch_account {
            name = "gmail";
            description = "Gmail";
            secret_names = [
                "gmail_address"
                "gmail_app_password"
            ];

            # Each label is its own folder, Gmail's other folders lose their [Gmail] prefix, and All Mail goes last so it only holds unlabelled archived mail
            source_arguments = ''
                --host1 imap.gmail.com --ssl1 \
                --user1 "$(< ${path_of "gmail_address"})" --passfile1 ${path_of "gmail_app_password"} \
                --exclude '^\[Gmail\]$' --exclude '^\[Gmail\]/(Important|Starred|Spam|Trash|Chats)$' \
                --folderlast '[Gmail]/All Mail' \
                --regextrans2 's,^\[Gmail\]/,,'
            '';
            main_folders = {
                "INBOX" = "INBOX";
                "[Gmail]/Drafts" = "Drafts";
                "[Gmail]/Sent Mail" = "Sent";
                "[Gmail]/All Mail" = "Archive";
            };
        })

        # Outlook ####################################################################################################################################
        (fetch_account {
            name = "outlook";
            description = "Outlook";
            secret_names = [ "outlook_address" ];
            prepare = ''
                mail-oauth token ${oauth_directory}/outlook.json --output "$RUNTIME_DIRECTORY/access-token"
            '';
            source_arguments = ''
                --host1 outlook.office365.com --ssl1 \
                --user1 "$(< ${path_of "outlook_address"})" \
                --authmech1 XOAUTH2 --oauthaccesstoken1 "$RUNTIME_DIRECTORY/access-token" \
                --exclude '^(Deleted|Deleted Items|Junk|Junk Email|Outbox)$' --exclude '^Sync Issues'
            '';
            main_folders = {
                "INBOX" = "INBOX";
                "Inbox" = "INBOX";
                "Drafts" = "Drafts";
                "Sent" = "Sent";
                "Archive" = "Archive";
            };
        })
    ];
}
