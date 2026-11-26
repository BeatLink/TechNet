# Mail ###############################################################################################################################################
#
# Moves mail off Gmail and Outlook.com into a Dovecot mailbox on Heimdall. imapsync copies every folder from each account on a timer into one
# shared Inbox, Drafts, Sent and Archive, with the rest under Gmail/ and Outlook/, then deletes
# what it copied from the account once delete_from_source is on. Mail clients read the mailbox over IMAP at mail.heimdall.technet:993, and a
# browser at https://mail.heimdall.technet, on the LAN and over WireGuard; sending still goes through each account's own SMTP server.
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
    secrets_file = "${config.technet.secrets.path}/mail.yaml";
    secret = name: config.sops.secrets.${name}.path;

    # Every message is deleted from its account once it has been copied here
    delete_from_source = true;

    mail-oauth = pkgs.writers.writePython3Bin "mail-oauth" { flakeIgnore = [ "E501" ]; } (builtins.readFile ./mail-oauth.py);

    # Stops a unit with a clear message while secrets/2-server/mail.yaml still holds the CHANGEME placeholders it ships with
    placeholder_check = names: ''
        for secret_file in ${lib.concatMapStringsSep " " secret names}; do
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
                        --user2 "$(< ${secret "mail_username"})" --passfile2 ${secret "mail_password"} \
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
                        restartUnits = [ "dovecot-users.service" ];
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
                    password_hash=$(${pkgs.mkpasswd}/bin/mkpasswd --method=yescrypt --stdin < ${secret "mail_password"})
                    umask 027
                    printf '%s:{CRYPT}%s\n' "$(< ${secret "mail_username"})" "$password_hash" > ${users_file}.new
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
            # 993 is open on the LAN, where split DNS sends the name at home, and over wireguard0, a trusted interface
            networking.firewall.interfaces.lan0.allowedTCPPorts = [ 993 ];

            services.nginx.streamConfig = ''
                server {
                    listen 993 ssl;
                    ssl_certificate ${config.sops.secrets.https_certificate.path};
                    ssl_certificate_key ${config.sops.secrets.https_certificate_key.path};
                    proxy_pass 127.0.0.1:${toString imap_port};
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
                --user1 "$(< ${secret "gmail_address"})" --passfile1 ${secret "gmail_app_password"} \
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
                --user1 "$(< ${secret "outlook_address"})" \
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
