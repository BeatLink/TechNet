# Radicale
#
# Radicale is a lightweight contacts and calendar manager for TechNet.
#
# Features
#   - Contacts
#   - Calendar
#   - Tasks
#

{
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
        "d /Storage/Services/Radicale 0750 radicale radicale --"
        "z /Storage/Services/Radicale 0750 radicale radicale --"
    ];

    nginx-vhosts.radicale = {
        domain = "radicale.heimdall.technet";
        port = 5232;
    };
}
