# Waydroid Location ##################################################################################################################################
#
# Feeds the host's geoclue fix into Android as a mock GPS provider, so Android apps locate without Waydroid having any GPS HAL of its own.
#

{ pkgs, lib, ... }:
let
    waydroidPackage = pkgs.waydroid-nftables;

    # `waydroid shell` runs as uid 0, and MOCK_LOCATION is checked against the caller, so the appop is granted to that uid rather than to
    # com.android.shell as the adb-based recipes do. Test providers do not survive a container restart, so the provider is rebuilt on every start.
    #
    # Setting the gps provider is enough to reach ordinary apps: Play Services' fused provider follows it, verified reading back
    # `last location=Location[fused ... mock]` after a single push.
    locationBridge = pkgs.writers.writePython3Bin "waydroid-location" {
        libraries = [ pkgs.python3Packages.pygobject3 ];
        flakeIgnore = [ "E501" ];
    } ''
        import signal
        import subprocess
        import sys
        import time
        import gi
        gi.require_version("Gio", "2.0")
        from gi.repository import Gio, GLib  # noqa: E402

        WAYDROID = ["/run/wrappers/bin/sudo", "-n", "${waydroidPackage}/bin/waydroid"]
        DESKTOP_ID = "waydroid-location"
        # 8 is GeoClue's exact level; anything lower rounds the fix to the city and navigation apps cannot use it.
        ACCURACY_EXACT = 8
        # Android is told about a move of at least this many metres, which keeps a walking fix live without a shell round trip per reading.
        DISTANCE_THRESHOLD = 5

        loop = GLib.MainLoop()
        state = {"stopping": False}


        def android(*args):
            """Run one command inside the container, ignoring its output."""
            return subprocess.run(WAYDROID + ["shell", "--"] + list(args), capture_output=True, text=True, timeout=60)


        def wait_booted():
            """Block until Android answers, because every command below is a no-op before that."""
            for _ in range(60):
                if state["stopping"]:
                    return False
                try:
                    if android("getprop", "sys.boot_completed").stdout.strip().startswith("1"):
                        return True
                except (subprocess.TimeoutExpired, OSError):
                    pass
                time.sleep(5)
            return False


        def install_provider():
            """Rebuild the mock gps provider that a container restart throws away."""
            android("appops", "set", "--uid", "0", "android:mock_location", "allow")
            android("cmd", "location", "set-location-enabled", "true")
            android("cmd", "location", "providers", "remove-test-provider", "gps")
            android("cmd", "location", "providers", "add-test-provider", "gps",
                    "--requiresSatellite", "--supportsAltitude", "--supportsSpeed", "--supportsBearing")
            android("cmd", "location", "providers", "set-test-provider-enabled", "gps", "true")


        def push(lat, lon, accuracy):
            """Hand one fix to Android."""
            args = ["cmd", "location", "providers", "set-test-provider-location", "gps",
                    "--location", "%f,%f" % (lat, lon)]
            if accuracy > 0:
                args += ["--accuracy", "%d" % int(accuracy)]
            android(*args)
            print("fix %.5f,%.5f +/-%dm" % (lat, lon, int(accuracy)), flush=True)


        system = Gio.bus_get_sync(Gio.BusType.SYSTEM)


        def location_of(path):
            proxy = Gio.DBusProxy.new_sync(
                system, Gio.DBusProxyFlags.NONE, None,
                "org.freedesktop.GeoClue2", path, "org.freedesktop.GeoClue2.Location", None,
            )
            return (proxy.get_cached_property("Latitude").get_double(),
                    proxy.get_cached_property("Longitude").get_double(),
                    proxy.get_cached_property("Accuracy").get_double())


        def on_signal(_proxy, _sender, name, params):
            if name != "LocationUpdated":
                return
            try:
                push(*location_of(params.unpack()[1]))
            except (GLib.Error, AttributeError) as err:
                print("update: %s" % err, flush=True)


        def shutdown():
            state["stopping"] = True
            android("cmd", "location", "providers", "remove-test-provider", "gps")
            loop.quit()
            return False


        if not wait_booted():
            sys.exit(1)
        install_provider()

        manager = Gio.DBusProxy.new_sync(
            system, Gio.DBusProxyFlags.NONE, None,
            "org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager",
            "org.freedesktop.GeoClue2.Manager", None,
        )
        client_path = manager.call_sync("GetClient", None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]

        props = Gio.DBusProxy.new_sync(
            system, Gio.DBusProxyFlags.NONE, None,
            "org.freedesktop.GeoClue2", client_path, "org.freedesktop.DBus.Properties", None,
        )
        for key, value in (("DesktopId", GLib.Variant("s", DESKTOP_ID)),
                           ("RequestedAccuracyLevel", GLib.Variant("u", ACCURACY_EXACT)),
                           ("DistanceThreshold", GLib.Variant("u", DISTANCE_THRESHOLD))):
            props.call_sync("Set", GLib.Variant("(ssv)", ("org.freedesktop.GeoClue2.Client", key, value)),
                            Gio.DBusCallFlags.NONE, -1, None)

        client = Gio.DBusProxy.new_sync(
            system, Gio.DBusProxyFlags.NONE, None,
            "org.freedesktop.GeoClue2", client_path, "org.freedesktop.GeoClue2.Client", None,
        )
        client.connect("g-signal", on_signal)
        client.call_sync("Start", None, Gio.DBusCallFlags.NONE, -1, None)

        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, shutdown)
        loop.run()
        sys.exit(0 if state["stopping"] else 1)
    '';
in
{
    services.geoclue2.appConfig.waydroid-location = {
        isAllowed = true;
        isSystem = true;
    };

    # Geoclue hands out no client at all until an agent is registered for the asking user -- every GetClient just times out, busctl included.
    # mkForce because the desktop module turns nixpkgs' demo agent off on the assumption the shell supplies one, and nothing here does.
    services.geoclue2.enableDemoAgent = lib.mkForce true;

    # A user service rather than a system one because that agent registers per uid, and the bridge has to be the same user to be served by it.
    home-manager.users.beatlink.systemd.user.services.waydroid-location = {
        Unit = {
            Description = "Feed the host's geoclue fix into Android as a mock GPS provider";
            PartOf = [ "waydroid-session.service" ];
            After = [ "waydroid-session.service" ];
        };
        Service = {
            ExecStart = "${locationBridge}/bin/waydroid-location";
            Restart = "always";
            RestartSec = 30;
        };
        Install.WantedBy = [ "waydroid-session.service" ];
    };
}
