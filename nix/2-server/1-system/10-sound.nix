{
    hardware.pulseaudio.enable = false;
    services = {
        pulseaudio.enable = false;
        pipewire = {
            enable = true;
            wireplumber.enable = true;
            systemWide = true;
        };
    };
}