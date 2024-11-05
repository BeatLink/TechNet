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
    };
    outputs = { self, nixpkgs-unstable, disko, impermanence, sops-nix, arion, home-manager,  ... }: rec {
        nixosConfigurations = {
            Ragnarok = nixpkgs-unstable.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    "${nixpkgs-unstable}/nixos/modules/installer/sd-card/sd-image.nix"
                    sops-nix.nixosModules.sops
                    ./0-common
                    ./1-backup-server
                ];                
            };
            Heimdall = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    sops-nix.nixosModules.sops
                    impermanence.nixosModules.impermanence
                    arion.nixosModules.arion
                    ./0-common
                    ./2-server
                ];
            };
            Odin = nixpkgs-unstable.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                    disko.nixosModules.disko
                    sops-nix.nixosModules.sops
                    impermanence.nixosModules.impermanence
                    ./0-common
                    ./3-laptop
                ];
            };
        };
        images.Ragnarok = nixosConfigurations.Ragnarok.config.system.build.sdImage;
    };
}