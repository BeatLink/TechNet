# Turns the screen back off after X-Nix wakes the phone for a job, since nobody is looking at it; the phone stays locked.
{ pkgs, ... }:
let
    screen_off = pkgs.writeShellScriptBin "screen-off" ''
        export XDG_RUNTIME_DIR=/run/user/1000
        exec ${pkgs.systemd}/bin/busctl --user set-property org.gnome.Mutter.DisplayConfig \
            /org/gnome/Mutter/DisplayConfig org.gnome.Mutter.DisplayConfig PowerSaveMode i 3
    '';
in
{
    environment.systemPackages = [ screen_off ];
    security.sudo.extraRules = [
        {
            users = [ "x-nix-agent" ];
            runAs = "beatlink";
            commands = [
                {
                    command = "/run/current-system/sw/bin/screen-off";
                    options = [ "NOPASSWD" ];
                }
            ];
        }
    ];
}
