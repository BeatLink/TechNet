{
    description = "flake for TechNet";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    };
    outputs = { self, nixpkgs, disko, impermanence, sops-nix, arion, home-manager,  ... }: {
        nixosConfigurations = {
            Ragnarok = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    sops-nix.nixosModules.sops
                    ./0-common/default.nix
                    ./1-backup-server.nix
                ];                
            };
            Heimdall = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    sops-nix.nixosModules.sops
                    impermanence.nixosModules.impermanence
                    arion.nixosModules.arion
                    ./0-common/default.nix
                    ./2-server/default.nix
                ];
            };
        };
    };
}