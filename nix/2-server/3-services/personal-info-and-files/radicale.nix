# Radicale
#
# Radicale is a lightweight contacts and calendar manager for TechNet.
#
# Features
#   - Contacts
#   - Calendar
#   - Tasks
#

{ pkgs, inputs, config, ... }:
{
    sops.secrets.radicale_vigil_password = {
        sopsFile = "${inputs.self}/secrets/2-server/radicale.yaml";
        owner = "vigil-access";
    };

    services.radicale = {
        enable = true;
        settings = {
            server = {
                hosts = [ "127.0.0.1:5232" ];
            };
            auth = {
                type = "htpasswd";
                htpasswd_filename = "/Storage/Services/Radicale/data/users";
                htpasswd_encryption = "bcrypt";
            };
            storage = {
                filesystem_folder = "/Storage/Services/Radicale/data/collections";
            };
        };
    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Radicale 0750 radicale radicale - -"
        "Z /Storage/Services/Radicale 0750 radicale radicale - -"
    ];

    # The htpasswd file is otherwise unmanaged by Nix (the real beatlink
    # login was added once by hand), so this only ever touches the single
    # `vigil` line — idempotent, and never overwrites the file wholesale.
    # Runs after radicale's tmpfiles rule so the parent directory exists,
    # and before radicale.service so an empty file is never read as "no
    # collections" (Radicale creates the file itself if absent, but this
    # keeps the ordering explicit rather than relying on that).
    systemd.services.radicale-vigil-htpasswd = {
        description = "Provision Vigil's Radicale probe account";
        before = [ "radicale.service" ];
        wantedBy = [ "radicale.service" ];
        serviceConfig = {
            Type = "oneshot";
            User = "radicale";
            Group = "radicale";
            LoadCredential = "vigil_password:${config.sops.secrets.radicale_vigil_password.path}";
        };
        script = ''
            ${pkgs.apacheHttpd}/bin/htpasswd -bB \
                /Storage/Services/Radicale/data/users \
                vigil "$(cat "$CREDENTIALS_DIRECTORY/vigil_password")"
        '';
    };

    nginx-vhosts.radicale = {
        domain = "radicale.heimdall.technet";
        port = 5232;
    };
}
