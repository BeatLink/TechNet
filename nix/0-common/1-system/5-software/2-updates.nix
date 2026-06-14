# Enables Automatic Upgrades ####################################################################################################################
{
    lib,
    ...
}:
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
        dates = lib.mkDefault "Sat 08:00";
        allowReboot = true;
        persistent = true;
    };
    systemd.services.nixos-upgrade = {
        postStop = ''
            if [ "$SERVICE_RESULT" == "success" ]; then
                echo "System upgrade successful at $(date '+%Y-%m-%d %H:%M:%S')"
            else
                echo "System upgrade failed at $(date '+%Y-%m-%d %H:%M:%S') with result: $SERVICE_RESULT"
            fi        
        '';
    };

}
