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

                packages = with pkgs; [ ciscoPacketTracer8 ];
                persistence."/Storage/Apps/Programming/PacketTracer" = {
                    directories = [
                    ];

                };
            };
        };
}
