{
    programs.dconf.enable = true;
    
    home-manager.users.beatlink = {pkgs, ...}: {
        home.packages = [ pkgs.dconf ];
        dconf.enable = true;  
        imports = [
            ./dconf-options.nix
        ];
    };

}