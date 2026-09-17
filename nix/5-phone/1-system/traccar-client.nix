# Traccar client #####################################################################################################################################
#
# Posts one geoclue fix to Heimdall's Traccar over the OsmAnd protocol and exits, rather than holding a client open: a held client keeps the modem's
# GNSS receiver powered all day instead of for as long as a fix takes.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    device = lib.toLower config.networking.hostName; # Has to exist as a device in Traccar before a report is stored, and can only be added in its web UI
    desktopId = "traccar-client";
    server = "http://heimdall.technet:5055"; # Reached over the tunnel, so it answers on mobile data as well as at home
    fixTimeout = 120;

    traccarClient =
        pkgs.writers.writePython3Bin "traccar-client"
            {
                libraries = [ pkgs.python3Packages.pygobject3 ];
                flakeIgnore = [ "E501" ];
            }
            ''
                import glob
                import sys
                import time
                import urllib.error
                import urllib.parse
                import urllib.request

                import gi
                gi.require_version("Gio", "2.0")
                from gi.repository import Gio, GLib  # noqa: E402

                SERVER = "${server}"
                DEVICE = "${device}"
                DESKTOP_ID = "${desktopId}"
                TIMEOUT = ${toString fixTimeout}
                GEOCLUE = "org.freedesktop.GeoClue2"

                # Geoclue reports a double it has no value for as the most negative double there is.
                UNSET = -1.7976931348623157e308
                # 8 is GeoClue's exact level; anything lower rounds the fix to the city, which is not a track.
                ACCURACY_EXACT = 8


                def battery():
                    """Charge percentage and whether it is charging, as the Traccar client app reports them."""
                    for path in sorted(glob.glob("/sys/class/power_supply/*")):
                        try:
                            if open(path + "/type").read().strip() != "Battery":
                                continue
                            capacity = open(path + "/capacity").read().strip()
                            status = open(path + "/status").read().strip()
                        except OSError:
                            continue
                        if capacity:
                            return capacity, status == "Charging"
                    return None, False


                def report(bus, path):
                    """Post one geoclue Location, returning whether the server took it."""
                    location = Gio.DBusProxy.new_sync(
                        bus, Gio.DBusProxyFlags.NONE, None,
                        GEOCLUE, path, GEOCLUE + ".Location", None,
                    )

                    def number(name):
                        value = location.get_cached_property(name)
                        return None if value is None else value.get_double()

                    latitude, longitude = number("Latitude"), number("Longitude")
                    if latitude is None or longitude is None:
                        return False

                    params = {"id": DEVICE, "lat": latitude, "lon": longitude, "timestamp": int(time.time())}

                    # Speed is metres per second, which is what geoclue reports and what the OsmAnd decoder converts from.
                    for key, name in (("altitude", "Altitude"), ("accuracy", "Accuracy"),
                                      ("speed", "Speed"), ("bearing", "Heading")):
                        value = number(name)
                        if value is not None and value != UNSET and value >= 0:
                            params[key] = value

                    level, charging = battery()
                    if level is not None:
                        params["batt"] = level
                        params["charge"] = "true" if charging else "false"

                    with urllib.request.urlopen(SERVER + "/?" + urllib.parse.urlencode(params), timeout=20) as response:
                        print("reported %(lat)s %(lon)s" % params, "->", response.status, flush=True)
                    return True


                def main():
                    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
                    manager = Gio.DBusProxy.new_sync(
                        bus, Gio.DBusProxyFlags.NONE, None,
                        GEOCLUE, "/org/freedesktop/GeoClue2/Manager", GEOCLUE + ".Manager", None,
                    )
                    client_path = manager.call_sync("GetClient", None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]

                    # Geoclue hands a client no fix at all under an id its config does not allow.
                    props = Gio.DBusProxy.new_sync(
                        bus, Gio.DBusProxyFlags.NONE, None,
                        GEOCLUE, client_path, "org.freedesktop.DBus.Properties", None,
                    )
                    for key, value in (("DesktopId", GLib.Variant("s", DESKTOP_ID)),
                                       ("RequestedAccuracyLevel", GLib.Variant("u", ACCURACY_EXACT))):
                        props.call_sync(
                            "Set", GLib.Variant("(ssv)", (GEOCLUE + ".Client", key, value)),
                            Gio.DBusCallFlags.NONE, -1, None)

                    client = Gio.DBusProxy.new_sync(
                        bus, Gio.DBusProxyFlags.NONE, None,
                        GEOCLUE, client_path, GEOCLUE + ".Client", None,
                    )
                    loop = GLib.MainLoop()
                    done = []

                    def attempt(path):
                        """Post the fix at this path and stop waiting, whatever the server makes of it."""
                        try:
                            if not report(bus, path):
                                return
                        # A phone off the tunnel, or a server that does not know this device, are both ordinary states here
                        except urllib.error.URLError as err:
                            print("traccar took no report:", err, flush=True)
                        done.append(True)
                        loop.quit()

                    # Raised inside a signal callback, an exception is printed by GLib and swallowed, so every path posts through attempt()
                    def on_signal(_proxy, _sender, name, params):
                        if name == "LocationUpdated":
                            attempt(params.unpack()[1])

                    client.connect("g-signal", on_signal)
                    client.call_sync("Start", None, Gio.DBusCallFlags.NONE, -1, None)

                    # Geoclue only signals on change, so a fix it already holds would otherwise wait for the next move.
                    held = client.get_cached_property("Location")
                    if held is not None and held.get_string() not in ("", "/"):
                        attempt(held.get_string())
                    if not done:
                        GLib.timeout_add_seconds(TIMEOUT, loop.quit)
                        loop.run()

                    client.call_sync("Stop", None, Gio.DBusCallFlags.NONE, -1, None)
                    if not done:
                        print("no fix within", TIMEOUT, "seconds", flush=True)


                try:
                    main()
                except GLib.Error as err:
                    print("geoclue:", err, file=sys.stderr, flush=True)
                    sys.exit(1)
            '';
in
{
    services.geoclue2.appConfig.${desktopId} = {
        isAllowed = true;
        isSystem = true; # Reports on its own rather than at the user's asking, so it is approved here instead of through the agent each time
    };

    # A user unit under beatlink: geoclue queues GetClient forever unless an agent is registered for the calling uid, and phosh registers one for this user alone
    home-manager.users.beatlink.systemd.user = {
        services.traccar-client = {
            Unit.Description = "Report this phone's position to Traccar";

            Service = {
                Type = "oneshot";
                ExecStart = lib.getExe traccarClient;
                ProtectHome = "read-only";
                ProtectSystem = "strict";
                NoNewPrivileges = true;
            };
        };

        timers.traccar-client = {
            Unit.Description = "Report this phone's position to Traccar every few minutes";

            Timer = {
                OnStartupSec = "3m";
                OnUnitActiveSec = "5m"; # The interval the Traccar client app itself defaults to
                AccuracySec = "30s"; # A tracker whose points are a minute out of place is not a tracker
            };

            Install.WantedBy = [ "timers.target" ];
        };
    };
}
