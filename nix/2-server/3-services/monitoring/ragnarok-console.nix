# Ragnarok Console ###################################################################################################################################
#
# Records what Ragnarok sends on UDP 6666 into this host's journal: its kernel log, memory use and netconsole.
#
{ lib, pkgs, ... }:
{
    config = lib.mkMerge [

        # Capture ####################################################################################################################################
        {
            systemd.services.ragnarok-console = {
                description = "Record Ragnarok's kernel log and memory use";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];
                serviceConfig = {
                    ExecStart = "${pkgs.socat}/bin/socat -u UDP-RECV:6666,reuseaddr STDOUT";
                    DynamicUser = true;
                    Restart = "always";
                    RestartSec = 5;
                };
            };
        }

        # Firewall ###################################################################################################################################
        {
            networking.firewall.interfaces.enp2s0f1.allowedUDPPorts = [ 6666 ];
        }
    ];
}
