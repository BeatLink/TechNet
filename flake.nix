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
            url = "github:GermanBread/declarative-flatpak/stable-v3";
        };
    };
    outputs = { self, nixpkgs-unstable, disko, impermanence, sops-nix, arion, home-manager,  flatpaks, ... }: rec {
        nixosConfigurations = {
            Ragnarok = nixpkgs-unstable.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    "${nixpkgs-unstable}/nixos/modules/installer/sd-card/sd-image.nix"
                    sops-nix.nixosModules.sops
                    ./systems/0-common
                    ./systems/1-backup-server
                ];                
            };
            Heimdall = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    sops-nix.nixosModules.sops
                    impermanence.nixosModules.impermanence
                    arion.nixosModules.arion
                    ./systems/0-common
                    ./systems/2-server
                ];
            };
            Odin = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    sops-nix.nixosModules.sops
                    impermanence.nixosModules.impermanence
                    ./systems/0-common
                    ./systems/3-laptop
                ];
            };
        };
        homeConfigurations = {
            "beatlink" = home-manager.lib.homeManagerConfiguration {
                pkgs = import nixpkgs-unstable { system = "x86_64-linux"; };
                modules = [
                    flatpaks.homeManagerModules.declarative-flatpak
                    ./users/beatlink
                ];
            };
        };

        images.Ragnarok = nixosConfigurations.Ragnarok.config.system.build.sdImage;
    };
}