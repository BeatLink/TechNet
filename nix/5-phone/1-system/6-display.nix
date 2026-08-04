{ pkgs, lib, ... }:
{
    # phocConfig sets xwayland = "immediate" below, and dropping
    # services.xserver.enable took Xwayland with it. Enabled directly so X11
    # applications still work; this pulls in the Xwayland binary only, not a
    # display manager.
    programs.xwayland.enable = true;

    services = {
        # No display manager. The phosh module does not use one -- it runs
        # phosh-session directly as a systemd service under `user`, with
        # PAMName = "login", and says so in its own source: "We are running
        # without a display manager". Phosh then presents its own lock screen,
        # which has the on-screen keypad a phone needs.
        #
        # services.xserver.enable would undo that. It turns on LightDM by
        # default, and both then run at once: lightdm-gtk-greeter took
        # /dev/dri/card1 and put a desktop login box with a password field and no
        # on-screen keyboard in front of a device with no keyboard, while phoc
        # ran alongside it. That is the same two-display-managers-fighting
        # problem documented for Odin in CLAUDE.md.
        #
        # displayManager.autoLogin and defaultSession were configured but dead:
        # nothing consumes them without a display manager, so they were not the
        # reason a login screen appeared, and removing the greeter is what
        # actually fixes it.
        xserver = {
            desktopManager.phosh = {
                enable = true;
                user = "beatlink";
                group = "beatlink";
                phocConfig = {
                    xwayland = "immediate";
                    outputs = {
                        DSI-1 = {
                            # 175%. Not a dconf setting: org.gnome.desktop.interface
                            # has only `scaling-factor`, which is an integer, and
                            # `text-scaling-factor`, which resizes fonts and nothing
                            # else. Real fractional output scaling is the
                            # compositor's, so it belongs here -- the module's type
                            # accepts a float.
                            #
                            # 720x1440 at 1.75 gives a 411x823 logical screen,
                            # against 360x720 at the previous 2. More fits on
                            # screen, which is what the on-screen keyboard needed.
                            scale = 1.75;
                            # No `rotate`. The panel is natively portrait at
                            # 720x1440, so a static rotate = "90" turned it
                            # permanently sideways -- which is what "stuck in
                            # landscape while the phone is vertical" was.
                            #
                            # It also left nothing for auto-rotation to do: the
                            # sensor and iio-sensor-proxy work and report
                            # orientation changes live, but a fixed transform in
                            # phoc's config is not something the shell overrides.
                            # Leaving it unset lets phosh drive the transform
                            # from the sensor instead.
                            mode = "720x1440";
                        };
                    };
                };
            };
        };
    };

    # phosh.service runs with PAMName = "login", so starting it is what makes
    # logind open a session and start user@1000.service -- the user systemd
    # manager that runs everything in home-manager's systemd.user.services.
    #
    # Nothing ordered that after home-manager's activation, and on this phone
    # activation takes about eleven seconds. Measured on the boot that prompted
    # this: phosh at 63.2s, home-manager-beatlink.service 63.3s -> 74.6s, and
    # the user manager reaching default.target at 74.5s. It enumerated
    # default.target.wants before linkGeneration had written the symlinks into
    # it, so syncthing.service -- enabled, correct, and with its symlink present
    # on disk a second later -- was simply never queued.
    #
    # home-manager's own fallback does not cover this either. Its activation
    # ends by reloading the user manager and starting anything newly enabled,
    # but only if `systemctl --user is-system-running` says running or degraded.
    # Mid-boot it says "starting", so activation logs "User systemd daemon not
    # running. Skipping reload." and nothing starts the unit. Whether the race
    # is won or lost varies boot to boot, which is why it looked intermittent.
    #
    # systemd-user-sessions.service is the barrier this is for, and
    # home-manager-<user>.service already declares Before on it; display
    # managers in nixpkgs are ordered after it for the same reason. The phosh
    # module, having no display manager, never picked that up.
    #
    # The cost is real: the session now waits for activation, so the shell
    # appears about eleven seconds later. That is the right trade -- starting
    # the session before the user's dotfiles and units are linked is a broader
    # correctness problem than one Syncthing unit.
    systemd.services.phosh.after = [ "systemd-user-sessions.service" ];

    # tty1 belongs to phosh, so nothing else may claim it.
    #
    # phosh.service declares Conflicts=getty@tty1.service, which means whichever
    # of the two starts last stops the other. nixpkgs drops autovt@tty1 from
    # getty.target only when a display manager is enabled -- and this host
    # deliberately has none, for the reasons above -- so getty.target goes on
    # wanting it. The getty module's own comment says why that is the dangerous
    # half:
    #
    #     We can't just rely on 'Conflicts=autovt@tty1.service' because
    #     'switch-to-configuration switch' will start 'autovt@tty1.service'
    #
    # Which is what kept happening. Every `switch` started getty@tty1, systemd
    # resolved the conflict by stopping phosh first, and the session died in the
    # middle of the rebuild -- measured: phosh stopped at 824.35s, getty started
    # at 825.15s. Restart=always does not undo it, because a unit stopped by an
    # explicit job stays stopped, so the phone was left with no shell at all.
    #
    # The other VTs are unaffected. logind hardcodes spawning autovt@ttyN on VT
    # switch, so Ctrl+Alt+F2 still gets a console on demand, and the serial
    # getty on ttyS0 -- the one that recovered this phone once already -- is a
    # separate unit this does not touch.
    systemd.targets.getty.wants = lib.mkForce [ ];

    # unpatched gnome-initial-setup is partially broken in small screens
    #services.gnome.gnome-initial-setup.enable = false;

    #environment.gnome.excludePackages = with pkgs.gnome3; [

    #];
    environment.systemPackages = with pkgs; [
        gnome-terminal
        pipes
        phosh-mobile-settings

        # stevia, the on-screen keyboard, defaults to the hunspell completer for
        # word prediction and there was no dictionary installed anywhere, so it
        # failed at every start:
        #
        #     Failed to init default completer 'hunspell':
        #       Failed to find dictionary for en-us
        #
        # Word completion is not why the keyboard fails to draw -- it logs
        # "Animation did not finish in time" immediately afterwards and still
        # reports itself Started -- but a daemon erroring on startup is a
        # variable worth removing before blaming the compositor, and the
        # dictionary is wanted regardless.
        hunspellDicts.en_US
    ];

    # The stk3310 is an ambient light sensor as well as a proximity sensor, so
    # phosh will track it unless told not to. This is only the default: a value
    # the user has already set through Settings lives in their own dconf
    # database and wins over anything declared here.
    programs.dconf.profiles.user.databases = [
        {
            settings = {
                "org/gnome/settings-daemon/plugins/power".ambient-enabled = false;
                "org/gnome/desktop/interface".show-battery-percentage = true;

                # Show every app in the grid rather than only the ones declaring
                # themselves mobile-friendly. The key is a flags type whose only
                # member is 'adaptive', so the empty list means "do not filter"
                # -- it is not an unset value. Without this the grid hides
                # anything without an adaptive hint behind "Show All Apps",
                # which on this phone is most of what is installed.
                #
                # mkEmptyArray rather than [ ]: an empty Nix list carries no
                # element type, so the generator cannot tell an empty `as` from
                # an empty `ai` and refuses it.
                "sm/puri/phosh".app-filter-mode =
                    lib.gvariant.mkEmptyArray lib.gvariant.type.string;

                # Widgets on the lock screen. The built-in status icons -- wifi,
                # bluetooth, battery -- are already drawn there; these are the
                # optional panels underneath the clock. Names are the .plugin
                # basenames from phosh's lib/phosh/plugins.
                "sm/puri/phosh/plugins".lock-screen = [
                    "media-players"
                    "upcoming-events"
                    "emergency-info"
                ];

                # Toggles in the pull-down, alongside the built-in wifi,
                # bluetooth, rotation and torch buttons phosh draws itself.
                # These are the optional ones, and every name here is a
                # .plugin shipped by the 0.56 build from 14-phosh-bump.nix.
                #
                # Syncthing is driven from here rather than a desktop tray app:
                # Odin runs syncthingtray, which is Qt and desktop-shaped, so
                # the phone uses phosh's own quick setting instead. It needs
                # syncbus on the session bus to do anything -- see
                # 3-apps/technet/syncbus.nix.
                #
                # location toggles org.gnome.system.location, which is why
                # geoclue2 has to stay enabled for the button to mean
                # anything; mobile-data and wifi-hotspot drive NetworkManager,
                # the first through ModemManager's connection and the second
                # by putting the wifi radio into shared mode.
                "sm/puri/phosh/plugins".quick-settings = [
                    "mobile-data-quick-setting"
                    "wifi-hotspot-quick-setting"
                    "location-quick-setting"
                    "dark-mode-quick-setting"
                    "caffeine-quick-setting"
                    "pomodoro-quick-setting"
                    "syncthing-quick-setting"
                ];

                # Extra top-bar icons, which the lock screen shares.
                # simple-custom-status-icon is deliberately left out: it shows
                # nothing until given an icon and a command to run.
                "mobi/phosh/shell/plugins".status-icons = [
                    "load-meter-status-icon"
                ];
            };
        }
    ];

    # After systemd-backlight, which restores the brightness saved at the last
    # shutdown and would otherwise land after this and undo it.
    systemd.services.backlight-max = {
        description = "Set the panel backlight to maximum at boot";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-backlight@backlight:backlight.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "backlight-max" ''
                for panel in /sys/class/backlight/*; do
                    [ -e "$panel/max_brightness" ] || continue
                    cat "$panel/max_brightness" > "$panel/brightness"
                done
            '';
        };
    };

    # Two entries in the app grid that are noise on a phone. The tour is a GNOME
    # Shell walkthrough for a desktop this device does not run, and the manual is
    # the NixOS HTML documentation -- readable, but not from a launcher on a
    # 720x1440 panel.
    #
    # documentation.nixos.enable covers the desktop entry and the generated HTML
    # both. gnome-tour arrives with services.gnome.core-shell, which the phosh
    # module turns on, so it has to be excluded rather than simply not added.
    documentation.nixos.enable = false;
    environment.gnome.excludePackages = [ pkgs.gnome-tour ];

    # Same route as the tour: services.gnome.core-os-services, which the phosh
    # module turns on, sets services.avahi.enable = mkDefault true. No other host
    # on the network runs it, and this one has no use for mDNS service discovery.
    #
    # It was also failing on every activation, which mattered more than the
    # service itself: switch-to-configuration returns non-zero when a unit fails
    # to start, and nixos-rebuild reports that as
    # "did you forget to use --ask-elevate-password?" -- so four consecutive
    # deploys looked like sudo failures when activation had in fact succeeded.
    # The underlying fault was a stale PID file it would not clean up:
    #
    #     open(/run/avahi-daemon//pid): File exists
    #     Failed to create PID file: File exists
    services.avahi.enable = false;

    environment.etc."machine-info".text = lib.mkDefault ''
        CHASSIS="handset"
    '';

}
