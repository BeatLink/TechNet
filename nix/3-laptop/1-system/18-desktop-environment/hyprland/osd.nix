# On Screen Display
#
# Cinnamon shows an on screen popup when the volume, brightness or a lock key changes, drawn by the Cinnamon
# shell itself. Hyprland has no shell component, so swayosd provides the same popups.
#
# This also covers Cinnamon's togglekeys-enable-osd from desktop/a11y/keyboard, which shows an indicator when
# caps lock or num lock is toggled.
#
# swayosd has no NixOS module in nixpkgs, so it is wired up by hand here. It comes in three parts:
#
#   libinput backend - a system service that watches the keyboard for caps lock and num lock. It runs as root
#                      because reading input devices needs access the user session does not have, and it owns
#                      the org.erikreider.swayosd D-Bus name, hence the system D-Bus policy from the package
#   udev rules       - make /sys/class/backlight writable by the video group so brightness can be changed
#   server           - a user service that draws the popups in the session
#
# swayosd-client is what the keybinds in ./hotkeys.nix would call to show a popup for volume and brightness.
# Those keybinds currently call wpctl and brightnessctl directly, which changes the value without drawing an
# OSD, so they are overridden below to go through swayosd-client instead.
#

{ config, pkgs, ... }:
let
    palette = config.technet.theme.palette;
in
{
    # Ships the libinput backend unit, the D-Bus policy and the backlight udev rules
    systemd.packages = [ pkgs.swayosd ];
    services.udev.packages = [ pkgs.swayosd ];
    services.dbus.packages = [ pkgs.swayosd ];

    systemd.services.swayosd-libinput-backend.wantedBy = [ "graphical.target" ];

    # Writing to /sys/class/backlight requires membership of the video group, which the udev rules above grant
    # write access to.
    users.users.beatlink.extraGroups = [ "video" ];

    environment.systemPackages = [ pkgs.swayosd ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            systemd.user.services.swayosd = {
                Unit = {
                    Description = "SwayOSD on screen display server";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };
                Service = {
                    ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
                    Restart = "on-failure";
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };

            # Cinnamon's OSD is a dark rounded panel centred near the bottom of the screen. This styles swayosd
            # with the same Mint-Y-Dark-Aqua palette used by the panels in ./waybar.nix.
            xdg.configFile."swayosd/style.css".text = ''
                window#osd {
                    background: rgba(30, 30, 30, 0.85);
                    border-radius: 12px;
                    border: 1px solid rgba(90, 192, 192, 0.4);
                }
                window#osd #container {
                    margin: 16px;
                }
                window#osd image,
                window#osd label {
                    color: #${palette.text};
                }
                window#osd progressbar:disabled,
                window#osd image:disabled {
                    opacity: 0.5;
                }
                window#osd progress {
                    background: #${palette.accent};
                    border-radius: 4px;
                }
                window#osd trough {
                    background: rgba(255, 255, 255, 0.2);
                    border-radius: 4px;
                }
            '';

            # Route the volume and brightness keys through swayosd-client so that changing them draws a popup,
            # the way Cinnamon does. These replace the wpctl and brightnessctl binds from ./hotkeys.nix.
            #
            # Cinnamon caps volume at 150% (desktop/sound maximum-volume), which swayosd expresses with
            # --max-volume.
            wayland.windowManager.hyprland.settings = {
                bindel = [
                    ", XF86AudioRaiseVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume raise --max-volume 150"
                    ", XF86AudioLowerVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume lower"
                    ", XF86MonBrightnessUp, exec, ${pkgs.swayosd}/bin/swayosd-client --brightness raise"
                    ", XF86MonBrightnessDown, exec, ${pkgs.swayosd}/bin/swayosd-client --brightness lower"
                ];
                bindl = [
                    ", XF86AudioMute, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle"
                    ", XF86AudioMicMute, exec, ${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle"
                ];
            };
        };
}
