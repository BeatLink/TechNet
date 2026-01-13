{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ ciscoPacketTracer8 ];
                persistence."/Storage/Apps/Programming/PacketTracer" = {
                    directories = [
                    ];
                    allowOther = true;
                };
            };
        };
}