{ pkgs, lib, ... }:
{
    services.xserver.desktopManager.phosh.enable = true;

    # unpatched gnome-initial-setup is partially broken in small screens
    #services.gnome.gnome-initial-setup.enable = false;

    #programs.phosh.enable = true;
    #environment.gnome.excludePackages = with pkgs.gnome3; [

    #];
    environment.systemPackages = with pkgs; [
        git
        gnome-terminal
        pipes
        terminal
        wget
    ];

    environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
    '';

}
