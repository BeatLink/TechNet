{
    description = "flake for TechNet";

    inputs = {
        nixpkgs = {
            url = "github:NixOS/nixpkgs/nixos-unstable";
        };
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        impermanence = {
           url = "github:nix-community/impermanence";
        };
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        arion = {
            url = "github:hercules-ci/arion";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        plasma-manager = {
            url = "github:nix-community/plasma-manager";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.home-manager.follows = "home-manager";
        };
        flatpaks = {
            url = "github:GermanBread/declarative-flatpak";
        };
    };
    outputs = { self, nixpkgs, disko, impermanence, sops-nix, arion, home-manager, plasma-manager, flatpaks, ... }: rec {
        nixosConfigurations = {
            Ragnarok = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    ./0-common
                    ./1-backup-server
                ];                
                specialArgs = { inherit impermanence; };
            };
            Heimdall = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    arion.nixosModules.arion
                    ./0-common
                    ./2-server
                ];
                specialArgs = { inherit impermanence; };
            };
            Odin = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    {home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];}
                    flatpaks.nixosModules.declarative-flatpak
                    ./0-common
                    ./3-laptop
                ];
                specialArgs = { inherit impermanence; };
            };
        };
        images.Ragnarok = nixosConfigurations.Ragnarok.config.system.build.sdImage;
    };
}