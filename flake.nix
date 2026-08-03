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
        mobile-nixos = {
            url = "github:NixOS/mobile-nixos";
            flake = false;
        };
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        impermanence = {
            url = "github:nix-community/impermanence";
        };
        arion = {
            url = "github:hercules-ci/arion";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        blockurl = {
            url = "github:BeatLink/BlockURL?dir=sync-server";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        xdg-autostart = {
            url = "github:Zocker1999NET/home-manager-xdg-autostart";
        };
        gmusicbrowser = {
            url = "github:BeatLink/gmusicbrowser-nix-flake";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixos-plymouth = {
            url = "github:BeatLink/nixos-plymouth";
        };
        vantage = {
            url = "github:nabilksabu/vantage-nix";
        };
        app-separators = {
            url = "github:/BeatLink/Plank-Separator";
        };
        claude-code = {
            url = "github:sadjow/claude-code-nix";
        };
        calibre-web-automated = {
            url = "github:BeatLink/Calibre-Web-Automated/nix-packing-final";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        lnxlink = {
            url = "github:BeatLink/lnxlink";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nix-vscode-extensions = {
            url = "github:nix-community/nix-vscode-extensions";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        vigil = {
            url = "path:/Storage/Files/Projects/Coding/Vigil";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        context = {
            url = "path:/Storage/Files/Projects/Coding/Context";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixtool = {
            url = "github:BeatLink/NixTool";
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
            blockurl,
            mobile-nixos,
            vantage,
            app-separators,
            claude-code,
            calibre-web-automated,
            lnxlink,
            ...
        }:
        {
            # Exposed so the PinePhone kernel can be built and cached on its own,
            # without evaluating a whole host. There is no megi/mobile-nixos
            # kernel in cache.nixos.org, so anyone running NixOS on a PinePhone
            # otherwise faces a multi-hour aarch64 build for a kernel that is
            # bit-identical for all of them.
            #
            # Taken from the host rather than rebuilt standalone deliberately: a
            # separate `pkgs` would differ from Thor's by overlays or config and
            # silently produce a second, unshared derivation, leaving the cache
            # useless for the one machine it was meant to serve.
            packages.aarch64-linux = {
                linux-pinephone-megi = self.nixosConfigurations.Thor.config.boot.kernelPackages.kernel;

                # ZFS is out-of-tree, so it is rebuilt against every new kernel
                # and is not in any cache either. Thor's root is on it.
                zfs-pinephone-megi = self.nixosConfigurations.Thor.config.boot.kernelPackages.zfs_2_4;
            };

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
                        blockurl.nixosModules.blockurl
                        calibre-web-automated.nixosModules.default
                        lnxlink.nixosModules.default
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
                                    lnxlink.homeModules.default
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
