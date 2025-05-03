{
    networking.firewall = rec {
        allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
        allowedUDPPortRanges = allowedTCPPortRanges;
    };
    home-manager.users.beatlink = { pkgs, lib, ... }: {
        imports = [                                                                 # Imports Pix Dconf Settings
            ./2-dconf-settings.nix
        ];
        services.kdeconnect = {
            enable = true;
            package = pkgs.valent;
        };
        home.persistence."/Storage/Apps/TechNet/Valent" = {
            directories = [
                ".cache/valent"
                ".config/valent"
            ];
            allowOther = true;
        };
        
        home.activation.valentCommands = lib.hm.dag.entryAfter ["writeBoundary"] ''
            echo "Generating and loading Valent runcommand settings into dconf..."

            # Generate the dconf ini file

            tee valentDconfFile <<-'EOF'
            [ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/runcommand]
            commands={'24da1a0e-920b-4ea2-b166-577bc0a3c307': <{'name': <'Shutdown'>, 'command': <'sudo systemctl poweroff'>}>, 'e5e5b2a9-9264-42e1-8aee-9ad9773f0802': <{'name': <'Sleep'>, 'command': <'systemctl suspend'>}>, '387b6a22-7144-469a-838a-9f5f5afc61b4': <{'name': <'Turn On Screen'>, 'command': <'xset -display $DISPLAY dpms force on'>}>, '07f552db-09e6-4271-bf7c-a6a424e2e231': <{'name': <'Lock Screen'>, 'command': <'cinnamon-screensaver-command -l'>}>, '31f2fd45-4939-452b-8b87-61a06d0e1fcf': <{'name': <'Unlock Screen'>, 'command': <'cinnamon-screensaver-command -d'>}>, '36912726-878d-4182-9e66-afcd8aaf2c5c': <{'name': <'Turn Off Screen'>, 'command': <'xset -display $DISPLAY dpms force off'>}>}
            EOF

            # Load the generated dconf file
            ${pkgs.dconf}/bin/dconf load / < valentDconfFile

            # Clean up the temporary file
            rm valentDconfFile
        '';
    };
}