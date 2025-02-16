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
        xdg-autostart = {
            url = "github:Zocker1999NET/home-manager-xdg-autostart";
        };
        flatpaks = {
            url = "github:GermanBread/declarative-flatpak";
        };
        flake-programs-sqlite =  {
            url = "github:wamserma/flake-programs-sqlite";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = inputs @ { 
            self, 
            nixpkgs, 
            disko, 
            impermanence, 
            sops-nix, 
            arion, 
            home-manager, 
            xdg-autostart,
            flatpaks, 
            flake-programs-sqlite, 
            ... 
        }:  {
        nixosConfigurations = {
            Ragnarok = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    ./0-common
                    ./1-backup-server
                ];                
                specialArgs = { inherit impermanence; inherit inputs; };
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
                specialArgs = { inherit impermanence; inherit inputs; };
            };
            Odin = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                    sops-nix.nixosModules.sops
                    home-manager.nixosModules.home-manager
                    {home-manager.sharedModules = [ xdg-autostart.homeManagerModules.xdg-autostart ];}
                    flatpaks.nixosModules.declarative-flatpak
                    flake-programs-sqlite.nixosModules.programs-sqlite
                    ./0-common
                    ./3-laptop
                ];
                specialArgs = { inherit impermanence; inherit inputs; };
            };
        };
    };
}