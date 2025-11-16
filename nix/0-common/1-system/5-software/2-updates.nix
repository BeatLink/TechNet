# Enables Automatic Upgrades ####################################################################################################################
{ pkgs, config, lib, ... }:
{
    system.autoUpgrade = {
        # Configures Automatic Upgrades at 2AM from my GitHub flake.
        enable = true;
        flake = "github:BeatLink/TechNet";
        operation = "switch";
        flags = [
            "--no-write-lock-file"
            "-L"
        ];
        dates = lib.mkDefault "18:00";
        allowReboot = true;
        persistent = true;
    };
    systemd.services.nixos-upgrade =
        let
            # Sends status updates to Uptime Kuma on Heimdall
            BaseURL = "https://uptime-kuma.heimdall.technet/api/push/";
            Keys = {
                Ragnarok = "sTgpl4hkEc";
                Odin = "Iy9Tfr31nG";
                Heimdall = "urMFRtdrYA";
                Thor = "jvrkzUvvrB";
            };
            FullURL = "${BaseURL}${Keys.${config.networking.hostName}}";
        in
        {
            postStop = ''
                if [ "$SERVICE_RESULT" == "success" ]; then
                    ${pkgs.wget}/bin/wget --spider --no-check-certificate "${FullURL}?status=up&msg=$(date '+%Y-%m-%d %H:%M:%S') System Upgrades Successful&ping=";
                else
                    ${pkgs.wget}/bin/wget --spider --no-check-certificate "${FullURL}?status=down&msg=$(date '+%Y-%m-%d %H:%M:%S') System Upgrades Failed&ping=";
                fi        
            '';
        };

}
