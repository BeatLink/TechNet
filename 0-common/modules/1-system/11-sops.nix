
{ config, lib, pkgs, modulesPath, ... }: 
{

    environment.systemPackages = with pkgs; [
        sops
    ];     
    sops.secrets.sops_age_secret_key = {
        sopsFile = ../../secrets/secrets.yaml;
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.file.".config/sops/age/keys.txt".source = config.sops.secrets.sops_age_secret_key.path;
    };
}
