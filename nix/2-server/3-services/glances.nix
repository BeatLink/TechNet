# Glances
#
# Glances is a dashboard and system monitor. 
#

{
    services.glances = {
        enable = true;
        extraArgs = [ 
            "--webserver"
            "--config"
            "/Storage/Services/Glances/glances.conf" 
        ];
    };
}