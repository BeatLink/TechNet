# Software ################################################################################################################################
#
# Enables flakes, allows unfree packages, enables auto upgrades and install default software                                                
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 

let 
    systemUpdateUptimeKumaURL = {
        Ragnarok = "https://uptime-kuma.heimdall.technet/api/push/sTgpl4hkEc";
        Odin = "https://uptime-kuma.heimdall.technet/api/push/Iy9Tfr31nG";
        Heimdall = "https://uptime-kuma.heimdall.technet/api/push/urMFRtdrYA"; 
    };

in {
    nix = {                                                             # Enables Flakes
        extraOptions = ''experimental-features = nix-command flakes'';
        settings.trusted-users = [ "root" "beatlink" ];                 # Allows me to remote update by sending the flake over ssh
        gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
        };
    };
    nixpkgs.config.allowUnfree = true;                                  # Allow unfree packages
    system.autoUpgrade = {
        enable = true;
        flake = "github:BeatLink/TechNet";
        operation = "switch";
        flags = [
            "--no-write-lock-file"
            "-L"
        ];
        dates = "02:00";
        randomizedDelaySec = "15min";
        allowReboot = true;
        persistent = true;
    };

    systemd.services.nixos-upgrade =  {
        preStart = ''
            wget --spider "${systemUpdateUptimeKumaURL.${config.networking.hostName}}?status=up&msg=System Upgrades Started&ping=";
        '';
        postStop =  ''
            if [ "$SERVICE_RESULT" == "success" ]; then
                wget --spider "${systemUpdateUptimeKumaURL.${config.networking.hostName}}?status=up&msg=System Upgrades Completed Successfully&ping=";
            else
                wget --spider "${systemUpdateUptimeKumaURL.${config.networking.hostName}}?status=down&msg=System Upgrades Failed&ping=";
            fi        
        '';
    };
    environment = {
        defaultPackages = lib.mkForce [];
        systemPackages = with pkgs; [                                   # Set packages installed on system
            wget                                                        # For downloading stuff
            htop                                                        # For checking the system status
            ncdu                                                        # For checking disk usage
            git                                                         # For downloading git repos
            nano
            tree                                                        # For editing config files
            curl
            iputils
            sops
            pciutils
            usbutils 
        ];
    };
    systemd.extraConfig = "DefaultLimitNOFILE=65536";                   # Increase number of open files (Steam, syncthing, etc)
}