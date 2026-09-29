# Dock rotation ######################################################################################################################################
#
# The keyboard case holds the phone in one landscape pose, so docking it takes phosh's rotation lock and turns the panel to match.
#
# Undocking puts back whatever lock and transform the session had before, which for an unlocked session means phosh re-runs its own orientation match.
#
# phosh refuses output changes while the screen is locked and exposes no usable lock state, so the service stays up and retries until it lands.
#
{ pkgs, ... }:
let
    # Measured on the docked phone: the panel sits at transform 3, which is the same pose iio-sensor-proxy reports as right-up.
    landscape = 3;

    flag = "/run/pinephone-keyboard-docked";

    dockRotation =
        pkgs.writers.writePython3Bin "keyboard-dock-rotation"
            {
                libraries = [ pkgs.python3Packages.pygobject3 ];
                flakeIgnore = [ "E501" ];
            }
            ''
                import os
                import subprocess
                import gi
                gi.require_version("Gio", "2.0")
                from gi.repository import Gio, GLib  # noqa: E402

                LOCK_KEY = "/org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock"
                FLAG = "${flag}"
                # Kept across reboots on purpose: a phone that reboots docked still has to know what to put back when the case comes off.
                PREF = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")) + "/keyboard-dock.pref"
                LANDSCAPE = ${toString landscape}
                DCONF = "${pkgs.dconf}/bin/dconf"
                RETRY_S = 5

                session = Gio.bus_get_sync(Gio.BusType.SESSION)
                display_config = Gio.DBusProxy.new_sync(
                    session, Gio.DBusProxyFlags.NONE, None,
                    "org.gnome.Mutter.DisplayConfig", "/org/gnome/Mutter/DisplayConfig",
                    "org.gnome.Mutter.DisplayConfig", None,
                )


                class NotReady(Exception):
                    pass


                def monitor_state():
                    serial, monitors, logical, _props = display_config.call_sync("GetCurrentState", None, Gio.DBusCallFlags.NONE, -1, None).unpack()
                    # Empty while the panel is blanked and for a moment while phosh brings its outputs up, which is where a session-start run used to crash.
                    if not monitors or not logical:
                        raise NotReady("no logical monitor: the panel is off or still coming up")
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


                def pref_read():
                    try:
                        with open(PREF) as f:
                            lock, transform = f.read().split()
                            return lock, int(transform)
                    except (OSError, ValueError):
                        return None


                def pref_write(lock, transform):
                    os.makedirs(os.path.dirname(PREF), exist_ok=True)
                    with open(PREF, "w") as f:
                        f.write(lock + " " + str(transform))


                def dock():
                    if pref_read() is None:
                        lock, transform = lock_read(), monitor_state()[4]
                        # Landscape under a lock at dock time is this service's own leftover from a session that ended docked, not a choice to put back.
                        if lock == "true" and transform == LANDSCAPE:
                            lock, transform = "false", 0
                        pref_write(lock, transform)
                    # Lock first: an unlocked session re-matches the accelerometer and turns the panel straight back.
                    lock_write("true")
                    set_transform(LANDSCAPE)


                def undock():
                    pref = pref_read()
                    if pref is None:
                        return
                    lock, transform = pref
                    if lock == "true":
                        set_transform(transform)
                    else:
                        # Releasing the lock is enough for the transform: phosh re-runs its own orientation match on unlock and on the next sensor change.
                        lock_write("false")
                    os.remove(PREF)


                pending = {"retry": None, "reason": None}


                def reconcile(*_):
                    if pending["retry"]:
                        GLib.source_remove(pending["retry"])
                        pending["retry"] = None
                    try:
                        dock() if docked() else undock()
                        pending["reason"] = None
                    except (NotReady, GLib.Error) as e:
                        if str(e) != pending["reason"]:
                            pending["reason"] = str(e)
                            print("waiting: " + str(e), flush=True)
                        pending["retry"] = GLib.timeout_add_seconds(RETRY_S, reconcile)
                    return False


                flag_monitor = Gio.File.new_for_path(FLAG).monitor_file(Gio.FileMonitorFlags.NONE, None)
                flag_monitor.connect("changed", reconcile)
                reconcile()
                GLib.MainLoop().run()
            '';
in
{
    home-manager.users.beatlink = {
        # The dock state is a system-side fact and rotation is a session-side one, so the flag file is what joins them.
        systemd.user.services.keyboard-dock-rotation = {
            Unit = {
                Description = "Turn the panel to landscape while the keyboard case is docked";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
            };
            Service = {
                ExecStart = "${dockRotation}/bin/keyboard-dock-rotation";
                Restart = "on-failure";
                RestartSec = 2;
            };
            Install.WantedBy = [ "graphical-session.target" ];
        };
    };
}
