{
    description = "flake for TechNet";

    inputs = {
        nixpkgs = {
            url = "github:NixOS/nixpkgs/nixos-unstable";
        };
        nixpkgs-stable = {
            url = "github:NixOS/nixpkgs/nixos-25.05";
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
            url = "github:BeatLink/plank-reloaded?dir=nix";
        };
        flake-programs-sqlite =  {
            url = "github:wamserma/flake-programs-sqlite";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = inputs @ { 
            self, 
            nixpkgs, 
            nixpkgs-stable,
            disko, 
            impermanence, 
            sops-nix, 
            arion, 
            home-manager, 
            xdg-autostart,
            plank-reloaded,
            flake-programs-sqlite, 
            ... 
        }:  {
        nixosConfigurations = {
            Ragnarok = 
                let
                    system = "x86_64-linux";
                    pkgs-stable = import nixpkgs-stable {
                        inherit system;
                        config.allowUnfree = true;
                    };
                in
                    nixpkgs.lib.nixosSystem {
                        system = "aarch64-linux";
                        modules = [
                            disko.nixosModules.disko
                            impermanence.nixosModules.impermanence
                            sops-nix.nixosModules.sops
                            home-manager.nixosModules.home-manager
                            ./0-common
                            ./1-backup-server
                                {
                                    home-manager.extraSpecialArgs = {
                                        inherit pkgs-stable;
                                    };
                                }
                        ];
                        specialArgs = {
                            inherit impermanence inputs pkgs-stable;
                        };
                    };
            Heimdall = 
                let
                    system = "x86_64-linux";
                    pkgs-stable = import nixpkgs-stable {
                        inherit system;
                        config.allowUnfree = true;
                    };
                in
                    nixpkgs.lib.nixosSystem {
                        inherit system;
                        modules = [
                            disko.nixosModules.disko
                            impermanence.nixosModules.impermanence
                            sops-nix.nixosModules.sops
                            home-manager.nixosModules.home-manager
                            arion.nixosModules.arion
                            ./0-common
                            ./2-server
                            {
                                home-manager.extraSpecialArgs = {
                                    inherit pkgs-stable;
                                };
                            }
                        ];
                        specialArgs = {
                            inherit impermanence inputs pkgs-stable;
                        };
                    };
            Odin = 
                let
                    system = "x86_64-linux";
                    pkgs-stable = import nixpkgs-stable {
                        inherit system;
                        config.allowUnfree = true;
                    };
                in
                    nixpkgs.lib.nixosSystem {
                        inherit system;
                        modules = [
                            disko.nixosModules.disko
                            impermanence.nixosModules.impermanence
                            sops-nix.nixosModules.sops
                            home-manager.nixosModules.home-manager
                            { home-manager.sharedModules = [ xdg-autostart.homeManagerModules.xdg-autostart ]; }
                            flake-programs-sqlite.nixosModules.programs-sqlite
                            ./0-common
                            ./3-laptop
                            {
                                home-manager.extraSpecialArgs = {
                                    inherit pkgs-stable;
                                    inherit plank-reloaded;
                                };
                            }
                        ];
                        specialArgs = {
                            inherit impermanence inputs pkgs-stable;
                        };
                    };
        };
    };
}