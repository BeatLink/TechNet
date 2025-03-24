# SSH #####################################################################################################################################
#
# Configures SSH for remote access and file transfers
#
# Settings
#   - Enable SSH Daemon
#   - Allow SFTP for file transfers
#   - Disable all except public key authentication
#   - Enable SSH in initrd for drive decryption
#   - Set initrd ssh authentication to my client key
#   - Set the initrd login command to the ask password agent
#   - Add initrd and main ssh public keys for identification
#   - Add configuration to login as root when accessing initrd and my user when accessing main ssh
#
###########################################################################################################################################

{
    services.openssh = {
        enable = true;
        allowSFTP = true;
        settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            challengeResponseAuthentication = false;
            PermitRootLogin = "no";
        };
        hostKeys = [
            { 
                type = "ed25519"; 
                path = "/persistent/etc/ssh/ssh_host_ed25519_key"; 
            }
        ];
    };
    boot.initrd = {
        network.ssh = {
            enable = true;
            authorizedKeys = [ 
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4GfJHxZu55mhQPpL1MqLCrS4ws/1ZUodC/QicApyGF beatlink@technet" 
            ];
            hostKeys = [
                "/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
            ];
        };
        systemd.users.root.shell = "/bin/bash";
    };
    programs.ssh = {
        knownHosts = {
            "ragnarok-boot" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINtSfkBwSLxZxsjO/cvDpeY6j3DA95qOMsapWBAjv2hu";
                hostNames = ["10.100.100.5" "ragnarok.technet" "ragnarok" "ragnarok-boot"];
            };
            "ragnarok" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIInjkzjQG+KUcN1roAomyDKJiJLaHbiKBd46GjSBTbi1";
                hostNames = ["10.100.100.5" "ragnarok.technet" "ragnarok" "ragnarok-boot"];
            };
            "heimdall-boot" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJoZQ1rR5JCvRHw0PykObtYgoEIonLL/vaomPc3qscGF";
                hostNames = ["192.168.0.2" "10.100.100.1"  "heimdall.technet" "heimdall" "heimdall-boot"];
            };
            "heimdall" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICBUbcOarWmNGo5LRtmpx8Tr7cW3nNO6UvfwMdv/qoMc";
                hostNames = ["192.168.0.2" "10.100.100.1" "heimdall.technet" "heimdall" "heimdall-boot"];
            };
            "odin-boot" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRPO+0Y6QP2ifSA5uMXaIn+aIzUnQFdShRp7QdeSNhg";
                hostNames = ["192.168.0.3" "10.100.100.2" "odin.technet" "odin" "odin-boot"];
            };
            "odin" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p";
                hostNames = ["192.168.0.3" "10.100.100.2" "odin.technet" "odin" "odin-boot"];
            };
        };
        extraConfig = ''
            Host ragnarok-boot
                User root
                HostName 10.100.100.5

            Host ragnarok
                User beatlink
                HostName 10.100.100.5

            Host heimdall-boot
                HostName 10.100.100.1
                User root

            Host heimdall
                HostName 10.100.100.1
                User beatlink

            Host odin-boot
                HostName 10.100.100.2
                User root

            Host odin
                HostName 10.100.100.2
                User beatlink
        '';
        startAgent = true;
    };
}