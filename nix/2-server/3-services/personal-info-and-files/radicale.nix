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
    # Owned by `vigil`, not `vigil-access`, unlike the probe credentials that
    # are read on the target host over SSH. Vigil's HTTP-style plugins resolve
    # `password_command` on the Vigil host itself at plugin construction --
    # a probe's ssh_config routes the request, not the password lookup -- so
    # this is read by vigil.service, which runs as `vigil`. Owning it
    # `vigil-access` made every PROPFIND probe send an empty password and fail
    # authentication every 10 minutes.
    #
    # radicale-vigil-htpasswd reads it via LoadCredential, which systemd
    # resolves as root before dropping to the radicale user, so that side is
    # unaffected by the owner.
    sops.secrets.radicale_vigil_password = {
        sopsFile = "${config.technet.secrets.path}/radicale.yaml";
        owner = "vigil";
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

    systemd.tmpfiles.settings."Radicale"."/Storage/Services/Radicale" = {
        d = {
            user = "radicale";
            group = "radicale";
            mode = "0750";
        };
        Z = {
            user = "radicale";
            group = "radicale";
            mode = "0750";
        };
    };

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
