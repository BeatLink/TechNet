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
            inputs.nixpkgs.follows = "nixpkgs";
        };
        arion = {
            url = "github:hercules-ci/arion";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        blockurl = {
            url = "github:BeatLink/BlockURL?dir=sync-server";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        xdg-autostart = {
            url = "github:Zocker1999NET/home-manager-xdg-autostart";
            inputs.nixpkgs.follows = "nixpkgs";
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
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Source only: the branch behind PR #2 packages itself, but its derivation
        # omits tkinter and crashes on launch, so nix/3-laptop builds its own.
        lenovo-control-center = {
            url = "github:webbrain-one/linux-control-centre-for-lenovo/webbrain/issue-1";
            flake = false;
        };
        app-separators = {
            url = "github:/BeatLink/Plank-Separator";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        claude-code = {
            url = "github:sadjow/claude-code-nix";
            inputs.nixpkgs.follows = "nixpkgs";
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
        weblaunch = {
            url = "path:/Storage/Files/Projects/Coding/WebLaunch";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixtool = {
            url = "github:BeatLink/NixTool";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # megi's PinePhone kernel. Deliberately does NOT follow nixpkgs: the
        # binary cache it publishes is built against its own pin, and overriding
        # nixpkgs changes the stdenv, changes the derivation, and turns a one
        # minute substitution back into a multi-hour aarch64 build.
        pinephone-kernel = {
            url = "github:BeatLink/PinePhoneKernel";
        };
        pinephone-charge = {
            url = "github:BeatLink/PinePhoneCharge";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        prewarm = {
            url = "github:BeatLink/Prewarm";
            inputs.nixpkgs.follows = "nixpkgs";
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
