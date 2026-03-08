# Enable Flakes #################################################################################################################################
{ inputs, config, ... }:
{

    sops.secrets.github_access_token_conf = {
        sopsFile = "${inputs.self}/secrets/0-common.yaml";
    };

    nix = {
        extraOptions = ''
            experimental-features = nix-command flakes
            !include ${config.sops.secrets.github_access_token_conf.path}
        '';
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };
    
    programs.command-not-found.enable = false;
    home-manager.users.beatlink = {
        programs.command-not-found.enable = false;
    };
}
