# Fail2Ban ###########################################################################################################################################
#
# Bans IPs that repeatedly fail SSH authentication, as defence in depth behind the key-only auth in 3-services/1-ssh.nix.
#

{
    services.fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "1h";
        bantime-increment = {
            enable = true;                                                      # Repeat offenders get longer bans each time
            maxtime = "1w";
        };
        ignoreIP = [
            "10.100.100.0/24"                                                   # TechNet internal network
            "192.168.0.0/24"                                                    # LAN
        ];
    };
}
