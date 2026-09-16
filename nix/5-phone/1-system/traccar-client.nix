# Traccar client #####################################################################################################################################
#
# Reports this phone's position to Heimdall's Traccar over the OsmAnd protocol, which is the only one that server starts a listener for.
#
# A timer rather than a daemon, because a geoclue client held open keeps the modem's GNSS receiver powered: each run asks for one fix, posts it and
# exits, so the radio is on for as long as a fix takes rather than all day. Five minutes is the interval the Traccar client app itself defaults to.
#
# The identifier below has to exist as a device in Traccar before a single report is stored. The server keeps its devices in its own database and
# offers no way to declare one, so that is a job for the web UI, once.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    device = lib.toLower config.networking.hostName;
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
                    sent = []

                    def on_signal(_proxy, _sender, name, params):
                        if name == "LocationUpdated" and report(bus, params.unpack()[1]):
                            sent.append(True)
                            loop.quit()

                    client.connect("g-signal", on_signal)
                    client.call_sync("Start", None, Gio.DBusCallFlags.NONE, -1, None)

                    # Geoclue only signals on change, so a fix it already holds would otherwise wait for the next move.
                    held = client.get_cached_property("Location")
                    if held is not None and held.get_string() not in ("", "/") and report(bus, held.get_string()):
                        sent.append(True)
                    else:
                        GLib.timeout_add_seconds(TIMEOUT, loop.quit)
                        loop.run()

                    client.call_sync("Stop", None, Gio.DBusCallFlags.NONE, -1, None)
                    if not sent:
                        print("no fix within", TIMEOUT, "seconds", flush=True)


                try:
                    main()
                except urllib.error.URLError as err:
                    # A phone with no route to the tunnel is an ordinary state, not a failure worth flagging
                    print("traccar unreachable:", err, flush=True)
                except GLib.Error as err:
                    print("geoclue:", err, file=sys.stderr, flush=True)
                    sys.exit(1)
            '';
in
{
    services.geoclue2.appConfig.${desktopId} = {
        isAllowed = true;
        isSystem = true; # A background service with no session behind it, so there is no agent to ask on its behalf
    };

    systemd.services.traccar-client = {
        description = "Report this phone's position to Traccar";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe traccarClient;
            DynamicUser = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            NoNewPrivileges = true;
            RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
            ];
        };
    };

    systemd.timers.traccar-client = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "3m";
            OnUnitActiveSec = "5m";
            AccuracySec = "30s"; # A tracker whose points are a minute out of place is not a tracker
        };
    };
}
