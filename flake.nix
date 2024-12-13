{
    description = "flake for TechNet";

    inputs = {
        nixpkgs-unstable = {
            url = "github:NixOS/nixpkgs/nixos-unstable";
        };
        nixos-hardware = {
            url = "github:NixOS/nixos-hardware/master";
        };
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
            url = "github:GermanBread/declarative-flatpak";
        };
    };
    outputs = { self, nixpkgs-unstable, nixos-hardware, disko, impermanence, sops-nix, arion, home-manager,  flatpaks, ... }: rec {
        nixosConfigurations = {
            Ragnarok = nixpkgs-unstable.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    "${nixpkgs-unstable}/nixos/modules/installer/sd-card/sd-image.nix"
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    ./0-common
                    ./1-backup-server
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
                    ./0-common
                    ./2-server
                ];
            };
            Odin = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    flatpaks.nixosModules.declarative-flatpak
                    nixos-hardware.nixosModules.lenovo-ideapad-15ach6
                    ./0-common
                    ./3-laptop
                ];
                specialArgs = { inherit impermanence; };
            };
        };
        images.Ragnarok = nixosConfigurations.Ragnarok.config.system.build.sdImage;
    };
}