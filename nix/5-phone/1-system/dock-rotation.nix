# Dock rotation ######################################################################################################################################
#
# The keyboard case holds the phone in one landscape pose, so docking it takes phosh's rotation lock and turns the panel to match.
#
# Undocking puts back whatever lock and transform the session had before, which for an unlocked session means phosh re-runs its own orientation match.
#
{ pkgs, ... }:
let
    # Measured on the docked phone: the panel sits at transform 3, which is the same pose iio-sensor-proxy reports as right-up.
    landscape = 3;

    flag = "/run/pinephone-keyboard-docked";

    dockRotation = pkgs.writers.writePython3Bin "keyboard-dock-rotation" {
        libraries = [ pkgs.python3Packages.pygobject3 ];
        flakeIgnore = [ "E501" ];
    } ''
        import os
        import subprocess
        import gi
        gi.require_version("Gio", "2.0")
        from gi.repository import Gio, GLib  # noqa: E402

        LOCK_KEY = "/org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock"
        FLAG = "${flag}"
        # Holds the pre-dock lock and transform, in the runtime directory so a reboot starts from the session's own state rather than a stale one.
        PREF = os.environ.get("XDG_RUNTIME_DIR", "/tmp") + "/keyboard-dock.pref"
        LANDSCAPE = ${toString landscape}
        DCONF = "${pkgs.dconf}/bin/dconf"

        session = Gio.bus_get_sync(Gio.BusType.SESSION)
        display_config = Gio.DBusProxy.new_sync(
            session, Gio.DBusProxyFlags.NONE, None,
            "org.gnome.Mutter.DisplayConfig", "/org/gnome/Mutter/DisplayConfig",
            "org.gnome.Mutter.DisplayConfig", None,
        )


        def monitor_state():
            serial, monitors, logical, _props = display_config.call_sync("GetCurrentState", None, Gio.DBusCallFlags.NONE, -1, None).unpack()
            connector = monitors[0][0][0]
            mode = next(m[0] for m in monitors[0][1] if m[6].get("is-current"))
            return serial, connector, mode, logical[0][2], logical[0][3]


        def set_transform(transform):
            serial, connector, mode, scale, current = monitor_state()
            if current == transform:
                return
            # Method 2 (persistent) is the only one phosh acts on: temporary configs are parsed and then dropped without being applied.
            args = GLib.Variant("(uua(iiduba(ssa{sv}))a{sv})", (serial, 2, [(0, 0, scale, transform, True, [(connector, mode, {})])], {}))
            display_config.call_sync("ApplyMonitorsConfig", args, Gio.DBusCallFlags.NONE, -1, None)


        def lock_read():
            out = subprocess.run([DCONF, "read", LOCK_KEY], capture_output=True, text=True, timeout=10).stdout.strip()
            return out if out else "false"


        def lock_write(value):
            subprocess.run([DCONF, "write", LOCK_KEY, value], capture_output=True, timeout=10)


        def docked():
            try:
                with open(FLAG) as f:
                    return f.read().strip() == "1"
            except OSError:
                return False


        def dock():
            if not os.path.exists(PREF):
                with open(PREF, "w") as f:
                    f.write(lock_read() + " " + str(monitor_state()[4]))
            # Lock first: an unlocked session re-matches the accelerometer and turns the panel straight back.
            lock_write("true")
            set_transform(LANDSCAPE)


        def undock():
            if not os.path.exists(PREF):
                return
            with open(PREF) as f:
                lock, transform = f.read().split()
            os.remove(PREF)
            if lock == "true":
                set_transform(int(transform))
            else:
                # Releasing the lock is enough for the transform: phosh re-runs its own orientation match on unlock.
                lock_write("false")


        dock() if docked() else undock()
    '';
in
{
    home-manager.users.beatlink = {
        systemd.user.services.keyboard-dock-rotation = {
            Unit = {
                Description = "Turn the panel to landscape while the keyboard case is docked";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
            };
            Service = {
                Type = "oneshot";
                ExecStart = "${dockRotation}/bin/keyboard-dock-rotation";
            };
            # Started at session start as well, so a session that begins already docked lands in landscape without waiting for a dock event.
            Install.WantedBy = [ "graphical-session.target" ];
        };

        # The dock state is a system-side fact and rotation is a session-side one, so the flag file is what joins them.
        systemd.user.paths.keyboard-dock-rotation = {
            Unit = {
                Description = "Watch the keyboard case dock state";
                PartOf = [ "graphical-session.target" ];
            };
            Path.PathChanged = flag;
            Install.WantedBy = [ "graphical-session.target" ];
        };
    };
}
