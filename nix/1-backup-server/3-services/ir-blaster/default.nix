# IR Blaster #########################################################################################################################################
# An HTTP API that stores infrared codes and sends them through a CH340 USB-serial board with an IR emitter on TX; ir-learn records new ones.
# It answers over WireGuard only, and keeps its codes on the data drive because learned codes cannot be rebuilt.
#

{ pkgs, ... }:
let
    port = 9620;
    codesDirectory = "/Storage/Services/IR-Blaster";
    device = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";

    irBlaster = pkgs.writers.writePython3Bin "ir-blaster" {
        libraries = [ pkgs.python3Packages.pyserial ];
        flakeIgnore = [ "E501" ];
    } (builtins.readFile ./ir-blaster.py);
in
{
    technet.irLearn.enable = true;

    users.users.ir-blaster = {
        isSystemUser = true;
        group = "ir-blaster";
        extraGroups = [ "dialout" ];
    };
    users.groups.ir-blaster = { };

    systemd.tmpfiles.settings."IR-Blaster".${codesDirectory}.d = {
        user = "ir-blaster";
        group = "ir-blaster";
        mode = "0750";
    };

    systemd.services.ir-blaster = {
        description = "Infrared code API on the CH340 board";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        unitConfig.RequiresMountsFor = [ codesDirectory ];
        serviceConfig = {
            ExecStart = "${irBlaster}/bin/ir-blaster --device ${device} --codes ${codesDirectory}/codes.json --port ${toString port}";
            User = "ir-blaster";
            Group = "ir-blaster";
            Restart = "on-failure";
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ codesDirectory ];
            NoNewPrivileges = true;
        };
    };
}
