{
    nixpkgs.config.permittedInsecurePackages = [
        "ciscoPacketTracer8-8.2.2"
    ];
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            nixpkgs.config.permittedInsecurePackages = [
                "ciscoPacketTracer8-8.2.2"
            ];
            home = {

                packages = with pkgs; [ (pkgs-unstable.ciscoPacketTracer8.override { packetTracerSource = /Storage/Apps/Programming/PacketTracer/CiscoPacketTracer_900_Ubuntu_64bit.deb; }) ];
                persistence."/Storage/Apps/Programming/PacketTracer" = {
                    directories = [
                    ];

                };
            };
        };
}
