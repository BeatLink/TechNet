{
    description = "flake for TechNet";

    inputs = {
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
        impermanence = {
           url = "github:nix-community/impermanence";
        };
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
        arion = {
            url = "github:hercules-ci/arion";
            inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
        flatpaks = {
            url = "github:BeatLink/declarative-flatpak";
        };
    };
    outputs = { self, nixpkgs-unstable, disko, impermanence, sops-nix, arion, home-manager,  flatpaks, ... }: rec {
        nixosConfigurations = {
            Ragnarok = nixpkgs-unstable.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    "${nixpkgs-unstable}/nixos/modules/installer/sd-card/sd-image.nix"
                    home-manager.nixosModules.home-manager
                    sops-nix.nixosModules.sops
                    ./systems/0-common
                    ./systems/1-backup-server
                ];                
            };
            Heimdall = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    arion.nixosModules.arion
                    ./systems/0-common
                    ./systems/2-server
                ];
            };
            Odin = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    flatpaks.nixosModules.declarative-flatpak
                    home-manager.nixosModules.home-manager
                    ./systems/0-common
                    ./systems/3-laptop
                ];
            };
        };
        homeConfigurations = {
            "beatlink" = home-manager.lib.homeManagerConfiguration {
                pkgs = import nixpkgs-unstable { system = "x86_64-linux"; };
                modules = [
                    ./users/beatlink
                ];
            };
        };
        images.Ragnarok = nixosConfigurations.Ragnarok.config.system.build.sdImage;
    };
}