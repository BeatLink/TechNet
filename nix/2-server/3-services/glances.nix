# Glances
#
# Glances is a dashboard and system monitor.
#

{
    services.glances = {
        enable = true;
        extraArgs = [
            "--webserver"
            "--enable-plugin"
            "smart"
            "--config"
            "/Storage/Services/Glances/glances.conf"
        ];
        port = 61208;
    };

    nginx-vhosts.glances = {
        domain = "glances.heimdall.technet";
        port = 61208;
    };
}
