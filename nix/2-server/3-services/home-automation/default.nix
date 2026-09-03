{
    imports = [
        ./frigate.nix
        ./home-assistant.nix
        ./lnxlink.nix
        ./mosquitto
        # ./traccar.nix                                             # Switched off: no tracker protocol was ever enabled, so it never received a position
        ./esphome

    ];
}
