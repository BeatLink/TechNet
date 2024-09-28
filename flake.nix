{
    description = "flake for TechNet";
    inputs = {
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixpkgs-tapir.url = "github:NixOS/nixpkgs/nixos-23.11";

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
    outputs = { self, nixpkgs-unstable, nixpkgs-tapir, disko, impermanence, sops-nix, arion, home-manager,  ... }: rec {
        nixosConfigurations = {
            Ragnarok = nixpkgs-unstable.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    "${nixpkgs-unstable}/nixos/modules/installer/sd-card/sd-image.nix"
                    sops-nix.nixosModules.sops
                    ./0-common/default.nix
                    ./1-backup-server/default.nix
                ];                
            };
            Heimdall = nixpkgs-unstable.lib.nixosSystem {
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
            iso = nixpkgs-unstable.lib.nixosSystem {
                modules = [
                    "${nixpkgs-unstable}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
                    "${nixpkgs-unstable}/nixos/modules/installer/cd-dvd/channel.nix"
                    ./hosts/iso/configuration.nix
                ];
            };
        };
        images.Ragnarok = nixosConfigurations.Ragnarok.config.system.build.sdImage;
    };
}