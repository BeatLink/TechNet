{
    description = "flake for TechNet";

    inputs = {
        nixpkgs = {
            url = "github:NixOS/nixpkgs/nixos-unstable";
        };
        nix-index-database = {
            url = "github:nix-community/nix-index-database";
            inputs.nixpkgs.follows = "nixpkgs";
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
        plank-reloaded = {
            url = "github:zquestz/plank-reloaded";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        gmusicbrowser = {
            url = "github:BeatLink/gmusicbrowser-nix-flake";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixos-plymouth.url = "github:BeatLink/nixos-plymouth";
        mobile-nixos = {
            url = "github:NixOS/mobile-nixos";
            flake = false;
        };

    };
    outputs =
        inputs@{
            self,
            nixpkgs,
            nix-index-database,
            disko,
            impermanence,
            sops-nix,
            arion,
            home-manager,
            xdg-autostart,
            gmusicbrowser,
            nixos-plymouth,
            mobile-nixos,
            ...
        }:
        {
            nixosConfigurations = {
                Ragnarok = nixpkgs.lib.nixosSystem {
                    system = "aarch64-linux";
                    modules = [
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        ./nix/0-common
                        ./nix/1-backup-server
                        {
                            home-manager.extraSpecialArgs = { inherit inputs; };
                        }
                    ];
                    specialArgs = { inherit inputs; };
                };
                Heimdall = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        arion.nixosModules.arion
                        ./nix/0-common
                        ./nix/2-server
                        {
                            home-manager.extraSpecialArgs = { inherit inputs; };
                        }
                    ];
                    specialArgs = { inherit inputs; };
                };
                Odin = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        nixos-plymouth.nixosModules.default
                        {
                            home-manager.sharedModules = [
                                xdg-autostart.homeManagerModules.xdg-autostart
                                gmusicbrowser.homeManagerModules.gmusicbrowser
                            ];
                        }
                        ./nix/0-common
                        ./nix/3-laptop
                        {
                            home-manager.extraSpecialArgs = { inherit inputs; };
                        }
                    ];
                    specialArgs = { inherit inputs; };
                };
                Thor = nixpkgs.lib.nixosSystem {
                    system = "aarch64-linux";
                    modules = [
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        ./nix/0-common
                        ./nix/5-phone
                        {
                            home-manager.extraSpecialArgs = { inherit inputs; };
                        }
                    ];
                    specialArgs = { inherit inputs; };
                };
            };
        };
}
