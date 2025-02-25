{ config, pkgs, ... }:
{
    system.stateVersion = "24.05"; # Did you read the comment?
    services.flatpak = {
        enable = true;
        debug = true;
        remotes = {
            "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
        };
    };
    environment.persistence."/persistent" = {
        directories = [
            "/var/lib/flatpak"
        ];
    };
}
