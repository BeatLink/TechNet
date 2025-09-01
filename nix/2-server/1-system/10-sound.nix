{
    services = {
        pulseaudio.enable = false;
        pipewire = {
            enable = true;
            pulse.enable = true;
            wireplumber.enable = true;
            systemWide = true;
        };
    };
}