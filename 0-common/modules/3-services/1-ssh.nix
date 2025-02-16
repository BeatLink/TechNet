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
        systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";
    };
    programs.ssh = {
        knownHosts = {
            "heimdall-boot".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJoZQ1rR5JCvRHw0PykObtYgoEIonLL/vaomPc3qscGF";
            "heimdall".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICBUbcOarWmNGo5LRtmpx8Tr7cW3nNO6UvfwMdv/qoMc";
        };
        extraConfig = ''
            Host heimdall-boot
                HostName 10.100.100.1
                User root

            Host heimdall
                HostName 10.100.100.1
                User beatlink
        '';
        startAgent = true;
    };
}