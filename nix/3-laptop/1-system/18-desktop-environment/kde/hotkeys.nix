{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        programs.plasma.hotkeys.commands =  {
            "RestartPlasma" = {
                name = "Restart Plasma";
                key = "Ctrl+Alt+Esc";
                command = "systemctl --user restart plasma-plasmashell.service";
            };
            "RestartDisplayManager" = {
                name = "Restart Display Manager";
                key = "Ctrl+Alt+Backspace";
                command = "sudo systemctl restart display-manager.service";
            };
        };
    };
}
