# Fail2ban ################################################################################################################################
#
# Enables Fail2Ban for service security
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    services.fail2ban = {
        enable = true;                                                  # Enables Fail2ban
        maxretry = 5;                                                   # Observe 5 violations before banning an IP
        ignoreIP = [ "10.100.100.0/24" "192.168.0.0/24" ];              # Ignore IP addresses from my wireguard network and the local network
        bantime = "24h";                                                # Set bantime to one day
        bantime-increment = {
            enable = true;                                              # Enable increment of bantime after each violation
            multipliers = "1 2 4 8 16 32 64";                           # Sets the multiplier for the bantime
            maxtime = "168h";                                           # Do not ban for more than 1 week
            overalljails = true;                                        # Calculate the bantime based on all the violations
        };
        jails = {
            apache-nohome-iptables = ''                                 # Block an IP address if it accesses a non-existent home directory.                
                filter = apache-nohome
                action = iptables-multiport[name=HTTP, port="http,https"]
                logpath = /var/log/httpd/error_log*
                backend = auto
                findtime = 600
                bantime  = 600
                maxretry = 5
            '';
        };
    };
}