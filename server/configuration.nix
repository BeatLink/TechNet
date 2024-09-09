# Home Server Configuration ###############################################################################################################
TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    # Imports #############################################################################################################################
    imports = [                                       
        ./hardware-configuration.nix
        ./disk-config.nix
    ];

    # Boot Loader ##########################################################################################################################
    # This section manages misc boot settings
    #######################################################################################################################################
    boot = {
        supportedFilesystems = [ "btrfs" ];
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = false;                           # This laptop doesn't play nice with EFI variables (Curse you Acer!)
        };
        initrd = {
            availableKernelModules = [
                "wireguard"                                             # Needed for wireguard in initrd for remote LUKS unlocking
                "r8169"                                                 # Ethernet NIC driver
            ];
            systemd.enable = true;
        };
    };

    # Networking ##########################################################################################################################    
    # The systemd.network configuration is used over networking or networkmanager as it has support for wireguard in initrd. Also, Systemd 
    # doesn't really separate networking between initrd and the main system so all networking is configured here. Subsequently, changing
    # network settings will usually require a restart (since the wireguard private key can only really be accessed from initrd)
    ######################################################################################################################################
    sops.secrets.wireguard_private_key.sopsFile = ./secrets.yaml;
    networking = {
        hostName = "Heimdall";                                          # Sets hostname
        nameservers = [ "10.100.100.1" "8.8.8.8" "1.1.1.1" ];           # Sets up dns
        firewall.checkReversePath = "loose";                            # Needed for wireguard
    };
    boot = {
        kernel.sysctl."net.ipv4.ip_forward" = 1;                        # Enables routing between peers for wireguard

        initrd = {
            secrets = {                                             # Sops doesn't work in initrd so we use boot.initrd.secrets
                "/wireguard_private_key" = config.sops.secrets.wireguard_private_key.path;
            };
        systemd = {
            services.fix_wireguard_key_perms = {            # The Wireguard privatekey must be owned by systemd-network to be used.
                description = "Set permissions for wireguard private key";
                wantedBy = [ "initrd.target" ];
                after = [ "initrd-nixos-copy-secrets.service" ];
                before = [ "systemd-networkd.service" ];
                unitConfig.DefaultDependencies = "no";
                serviceConfig.Type = "oneshot";
                script = '' chown systemd-network:systemd-network /wireguard_private_key '';
            };
            network = {
                enable = true;
                netdevs."01-wireguard" = {
                    netdevConfig = {
                        Kind = "wireguard";
                        Name = "wg0";
                        MTUBytes = "1280";
                    };
                    wireguardConfig = {
                        PrivateKeyFile = /wireguard_private_key;
                        ListenPort = 51820;
                    };
                    wireguardPeers = [
                        {
                            # Laptop
                            PublicKey = "WlTdwgmdSvXTGjB+kaOkZEV9vyOk/fKELv3IkRdJOAE=";
                            AllowedIPs = ["10.100.100.2/32"];
                        }
                        {
                            # Tablet 
                            PublicKey = "LneSvdXvU9Y/+DROhb+qVGgxkjpT9KtW2ifMADDJ0HM=";
                            AllowedIPs = ["10.100.100.3/32"];
                        }
                        {
                            # Phone
                            PublicKey = "/TCFjby/XxSkAQxuWcL5Kv5ggOlYJtloyU+z1I8wGWs=";
                            AllowedIPs = ["10.100.100.4/32"];
                        }
                        {
                            # Backup Server
                            PublicKey = "rntfoR0iPjL90MhrwIFOVI0hSoZ8hHj8A512Q4+1hk4=";
                            AllowedIPs = ["10.100.100.5/32"];
                        }
                    ];
                };
                networks = {
                    "01-enp2s0f1" = {
                        matchConfig.Name = "enp2s0f1";
                        address = [ "192.168.0.2/24"];
                        gateway = ["192.168.0.1"];
                        linkConfig.RequiredForOnline = "routable";
                    };
                    "01-wireguard" = {
                        matchConfig.Name = "wg0";
                        address = ["10.100.100.1/24"];
                        networkConfig = {                           # Enables forwarding of VPN traffic to the internet
                            IPMasquerade = "ipv4";
                            IPv4Forwarding = true;
                        };
                    };
                };               
            };
        };
    };

    # Initrd SSH ##########################################################################################################################
    # Enables SSH in Boot for Remote LUKS Unlock
    #######################################################################################################################################
    boot.initrd = {
        network.ssh = {                                             
            port = 22;
            enable = true;
            authorizedKeys = [ 
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYQ9aXy5sS9PCKopaB58c8ZA/JGOEoBLMSg4a0n4aw7 beatlink@heimdall" 
            ];
            hostKeys = [
                "/persistent/etc/ssh/ssh_host_ed25519_key"
                "/persistent/etc/ssh/ssh_host_rsa_key"
            ];
        };
        systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };

    # Rollback Root #######################################################################################################################
    # The rollback service below clears the BTRFS root filesystem to a clean snapshot in order to prevent the buildup of state.
    # Everything should either be generated from this config file, stored in /persistent or stored on the data drives
    # See https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html 
    # https://discourse.nixos.org/t/impermanence-vs-systemd-initrd-w-tpm-unlocking/25167/3
    #######################################################################################################################################
    boot.initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        after = [ "systemd-cryptsetup@heimdall_crypt.service" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
            mkdir -p /mnt &&
            mount -o subvol=/ /dev/mapper/heimdall_crypt /mnt
            btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read subvolume; do
            echo "deleting /$subvolume subvolume..."
            btrfs subvolume delete "/mnt/$subvolume"
            done &&
            echo "deleting /root subvolume..." &&
            btrfs subvolume delete /mnt/root
            echo "restoring blank /root subvolume..." &&
            btrfs subvolume snapshot /mnt/root-blank /mnt/root                        
            umount /mnt
        '';
    };

    # Storage Drive Setup #################################################################################################################
    # The majority of state including docker databases and storage drives are stored on 2 1TB Hard Drives configured for RAID 1 with a LUKS
    # overlay on top. These settings decrypt that drive during boot
    #######################################################################################################################################
    boot = {
        swraid = {                                                      # Enables RAID for the data storage drive
            enable = true;
            mdadmConf = ''
                ARRAY /dev/md/0  metadata=1.2 UUID=218b060a:70baa2ea:ca8ece09:96675c63 name=Heimdall:0
                PROGRAM /bin/wall
            '';
        };    
        initrd.luks.devices.Storage.device = "/dev/md/0";               # Decrypts the data storage drive
    };
    fileSystems."/Storage" = {
        device = "/dev/mapper/Storage";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };
    systemd.tmpfiles.rules = [ "d /Storage 1770 beatlink beatlink" ];    # Creates the mount point and sets needed permissions
        
    # Software Management################################################################################################################## 
    This section handles enabling flakes, configuring upgrades and installing additional system packages
    #######################################################################################################################################                                                   
    nix = {                                                             # Enables Flakes
        package = pkgs.nixFlakes;
        extraOptions = ''experimental-features = nix-command flakes'';
        settings.trusted-users = [ "root" "beatlink" ];                 # Allows me to remote update by sending the flake over ssh
    };
    system.autoUpgrade.allowReboot = lib.mkForce  false;                # Prevents rebooting since LUKS manual decryption is needed
    environment.systemPackages = with pkgs; [                           # Set packages installed on system
        arion
        docker-client
    ];    
    
    # Borgmatic ###########################################################################################################################
    This handles backing up my server's docker files to my laptop and to my backup server
    #######################################################################################################################################
    services.borgmatic = {
        enable = true;
        configurations = {
            server-backups = {
                location = {
                    source_directories = [
                        "/Storage/Services"
                    ];
                    exclude_patterns = [
                        "/Storage/Files/Backups/Server"
                    ];
                    exclude_if_present = [
                        ".nobackup"
                        ".stversions"
                        ".thumbnails"
                    ];
                    repositories = [
                        "/Storage/Files/Backups/Server/Borgmatic"
                        "ssh://beatlink@10.100.100.2/media/beatlink/Storage/Files/Backups/Server/Borgmatic"
                    ];
                    one_file_system = true;
                };
                storage = {
                    compression = "lz4";
                    archive_name_format = "backup-{now}";
                    relocated_repo_access_is_ok = true;
                };
                retention = {
                    keep_hourly = 1;
                    keep_daily = 1;
                    keep_weekly = 1;
                    keep_monthly = 1;
                    keep_yearly = 1;
                    prefix = "backup-";
                };
                consistency = {
                    checks = [
                        "repository"
                        "archives"
                    ];
                    check_last = 3;
                    prefix = "backup-";
                };
                hooks = {
                    before_backup = [
                        "echo Starting a backup job."
                    ];
                    after_backup = [
                        "echo Backup created."
                    ];
                    on_error = [
                        "echo Error while creating a backup."
                    ];
                };
            };
        };
    };

    # Docker ##############################################################################################################################
    Almost all server services are provisioned with docker. These settings configure it. I may move to arion or nix containers at some point
    #######################################################################################################################################
    virtualisation.docker = {
        enable = true;
        liveRestore = false;                            # Solves hangs on shutdown
    };
    environment.persistence."/persistent".directories = ["/var/lib/docker"];
    networking.firewall = {
        logRefusedConnections = true;
        allowedTCPPorts = [
            80                                          # Nginx Services
            81                                          # Nginx Web Admin
            443                                         # Nginx Services (HTTPS)
            53                                          # Pihole DNS
            82                                          # Pihole Web Admin
        ];
        allowedUDPPorts = [
            53                                          # Pihole DNS
        ];                                
    };
    users.extraGroups.docker.members = [ "beatlink" ];
}
