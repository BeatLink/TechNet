{
    description = "flake for TechNet";

    inputs = {
        nixpkgs = {
            url = "github:NixOS/nixpkgs/nixos-unstable";
        };
        nixpkgs-stable = {
            url = "github:NixOS/nixpkgs/nixos-25.05";
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
            nixpkgs-stable,
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
                    specialArgs = { inherit inputs; };
                    modules = [
                        { nixpkgs.hostPlatform = "aarch64-linux"; }
                        { home-manager.extraSpecialArgs = { inherit inputs; }; }
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        ./nix/0-common
                        ./nix/1-backup-server
                    ];
                };
                Heimdall = nixpkgs.lib.nixosSystem {
                    specialArgs = { inherit inputs; };
                    modules = [
                        { nixpkgs.hostPlatform = "x86_64-linux"; }
                        { home-manager.extraSpecialArgs = { inherit inputs; }; }
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        arion.nixosModules.arion
                        ./nix/0-common
                        ./nix/2-server
                    ];
                };
                Odin = nixpkgs.lib.nixosSystem {
                    specialArgs = { inherit inputs; };
                    modules = [
                        { nixpkgs.hostPlatform = "x86_64-linux"; }
                        {
                            home-manager = {
                                extraSpecialArgs = { inherit inputs; };
                                sharedModules = [
                                    xdg-autostart.homeManagerModules.xdg-autostart
                                    gmusicbrowser.homeManagerModules.gmusicbrowser
                                ];
                            };
                        }
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        nixos-plymouth.nixosModules.default
                        ./nix/0-common
                        ./nix/3-laptop
                    ];
                };
                Thor = nixpkgs.lib.nixosSystem {
                    specialArgs = { inherit inputs; };
                    modules = [
                        { nixpkgs.hostPlatform = "aarch64-linux"; }
                        { home-manager.extraSpecialArgs = { inherit inputs; }; }
                        nix-index-database.nixosModules.nix-index
                        disko.nixosModules.disko
                        impermanence.nixosModules.impermanence
                        sops-nix.nixosModules.sops
                        home-manager.nixosModules.home-manager
                        ./nix/0-common
                        ./nix/5-phone
                    ];
                };
            };
        };
}
