# NextCloud ###############################################################################################################################
#
# NextCloud is the Personal Information Manager (PIM) hub of the TechNet. 
# 
# Features
#   - Contacts
#   - Calendar
#   - Tasks
#   - Phone Tracking
#   - Files
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion = {
        backend = "docker";
        projects.nextcloud = {
            serviceName = "nextcloud";
            settings = {
                services = {
                    db.services = {
                        image = "mariadb:latest";
                        container_name = ""
                    }
                }
                imports = [ ./arion-compose.nix ];
            };
        };
    };
}


# Time and Date
# Weather
# Emails
# RSS Feeds
# Calendar
# Todos
# Notes
# Communications

# Phone Notifications
# Computer notifications
