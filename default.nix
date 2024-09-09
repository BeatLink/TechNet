# Common Configurations 

{ config, lib, pkgs, modulesPath, ... }: 
{

    # Credential Management ###############################################################################################################
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];

    # System Settings #####################################################################################################################

    # Networking --------------------------------------------------------------------------------------------------------------------------
    networking = {
        domain = "TechNet";
        firewall = {
            enable = true;                                              # Enable the Firewall
            allowedTCPPorts = [
                22                                                      # Enables SSH in the firewall
            ];
            allowedUDPPorts = [ 
                5353                                                    # Enables Avahi
                51820                                                   # Allows Wireguard on Firewall
            ];                                
        };
    };

    # System Updates ----------------------------------------------------------------------------------------------------------------------
    system.stateVersion = "23.11";                                      # Sets the base version. Don't change unless reinstalling everything
        
    # Software ----------------------------------------------------------------------------------------------------------------------------
    nixpkgs.config.allowUnfree = true;                                  # Allow unfree packages
    environment.systemPackages = with pkgs; [                           # Set packages installed on system
        wget                                                            # For downloading stuff
        curl                                                            # Also for downloading stuff
        htop                                                            # For checking the system status
        ncdu                                                            # For checking disk usage
        git                                                             # For downloading git repos
        nano                                                            # For editing config files
    ];

    # Language and Time -------------------------------------------------------------------------------------------------------------------
    time.timeZone = "America/Jamaica";                                  # Sets time zone.
    i18n.defaultLocale = "en_US.UTF-8";                                 # Sets locale.

    # User Accounts ----------------------------------------------------------------------------------------------------------------------
    sops.secrets.beatlink_hashed_password = {
        sopsFile = ./secrets.yaml;
        neededForUsers = true;
    };
    users = {
        mutableUsers = false;                                           # Have users be managed by NixOS Config File
        groups."beatlink" = {};                                         # Creates group for my account
        users = {
            root.hashedPassword = "!";                                  # Disables Root Account
            "beatlink" = {                                              # Creates my account
                isNormalUser = true;                                    # Real (non service) user
                description = "BeatLink";                               # Sets the name of the user
                hashedPasswordFile = config.sops.secrets.beatlink_hashed_password.path;    # Sets my password using sops
                group = "beatlink";                                     # Adds me to my group
                extraGroups = [ "networkmanager" "wheel"];              # Allows management of the network and using sudo
                # packages = with pkgs; [                               # Installs user specific packages
                # ];
            };
        };
    };
    security.sudo.wheelNeedsPassword = false;                           # Removes the need for entering passwords for sudo

    # Persistence -------------------------------------------------------------------------------------------------------------------------
    environment.persistence."/persistent" = {
        hideMounts = true;
        directories = [
            "/var/lib/nixos"
            "/var/log"
        ];
        files = [
            "/etc/machine-id"
        ];
    };

    # Core Services #######################################################################################################################
    
    # Avahi -------------------------------------------------------------------------------------------------------------------------------    
    services.avahi = {
        enable = true;                                                  # Enables Avahi for LAN access via hostname.local
        publish = {
            enable = true;                                              # Publishes the device so others can find it
            addresses = true;                                           # Publishes our address so others can find it
            workstation = true;                                         # Marks this device as a PC (Set to false for servers)
        };
    };

    # SSH ---------------------------------------------------------------------------------------------------------------------------------
    services.openssh = {
        enable = true;                                                  # Enable the OpenSSH daemon.
        allowSFTP = true;                                               # Allows file transfers over SSH
        settings = {
            PasswordAuthentication = false;                             # Disables password based login
            KbdInteractiveAuthentication = false;                       # Disables keyboard based login
            PermitRootLogin = "no";                                     # Disables root login
        };
        hostKeys = [
            { type = "ed25519"; path = "/persistent/etc/ssh/ssh_host_ed25519_key"; }
            { type = "rsa"; bits = 4096; path = "/persistent/etc/ssh/ssh_host_rsa_key"; }
        ];
    };
    users.users."beatlink".openssh.authorizedKeys.keys = [              # Sets the SSH key for the user
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYQ9aXy5sS9PCKopaB58c8ZA/JGOEoBLMSg4a0n4aw7 beatlink@heimdall"
    ]; 
    systemd.tmpfiles.rules = [                                          # Sets permissions for SSH folder 
        "d /etc 0755 root root"
        "d /etc/ssh 0755 root root"
    ];

    # Fail2ban ----------------------------------------------------------------------------------------------------------------------------
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
