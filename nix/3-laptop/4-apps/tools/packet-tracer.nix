# Cisco Packet Tracer, the network simulator; nixpkgs cannot fetch its installer, so the .deb is added to the store by hand (see docs/odin.md)
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ cisco-packet-tracer_9 ];
                persistence."/Storage/Apps/Tools/PacketTracer" = {
                    directories = [
                        ".config/Cisco"
                        "Cisco Packet Tracer 9.0.1"
                    ];
                };
            };
        };
}
