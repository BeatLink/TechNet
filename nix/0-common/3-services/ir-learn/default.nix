# IR Learn ###########################################################################################################################################
# An HTTP API on port 9621 that learns an infrared code from one button press, heard through a receiver wired into a USB sound card's mic input.
# It answers over WireGuard only and can hand each code to an ir-blaster to store.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.irLearn;

    irLearn = pkgs.writers.writePython3Bin "ir-learn" { flakeIgnore = [ "E501" ]; } (
        builtins.readFile ./ir-learn.py
    );
in
{
    options.technet.irLearn = {
        enable = lib.mkEnableOption "learning infrared codes through a receiver on a USB sound card";

        device = lib.mkOption {
            type = lib.types.str;
            default = "hw:CARD=Device,DEV=0";
            description = "ALSA capture device the receiver is wired into.";
        };

        mixerCard = lib.mkOption {
            type = lib.types.str;
            default = "Device";
            description = "ALSA card whose gain controls are set before each recording.";
        };

        blaster = lib.mkOption {
            type = lib.types.str;
            default = "http://127.0.0.1:9620";
            description = "ir-blaster API that learned codes given a name are stored on.";
        };
    };

    config = lib.mkIf cfg.enable {
        systemd.services.ir-learn = {
            description = "Infrared code learning from a USB sound card";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = [ pkgs.alsa-utils ];
            serviceConfig = {
                ExecStart = "${irLearn}/bin/ir-learn --device ${cfg.device} --mixer-card ${cfg.mixerCard} --blaster ${cfg.blaster}";
                DynamicUser = true;
                SupplementaryGroups = [ "audio" ];
                Restart = "on-failure";
            };
        };
    };
}
