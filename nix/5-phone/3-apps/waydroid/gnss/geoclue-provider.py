"""
Geoclue location provider.

Follows the host's geoclue2 fix and hands it to the GNSS HAL, so Android sees
a real satellite provider rather than a mock one.
"""

import logging
from typing import Any, Callable, Dict, Optional

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

from .base import LocationProvider

# Geoclue reports a double it has no value for as the most negative double there is.
UNSET = -1.7976931348623157e308


class GeoclueLocationProvider(LocationProvider):
    """Provider that follows the host's geoclue2 fix."""

    # Allow-listed in the host's services.geoclue2.appConfig; a different id here is refused a client.
    DESKTOP_ID = "waydroid-gnss"
    # 8 is GeoClue's exact level; anything lower rounds the fix to the city and navigation cannot use it.
    ACCURACY_EXACT = 8
    # Metres of movement before geoclue reports again, which keeps a walking fix live without a wakeup per reading.
    DISTANCE_THRESHOLD = 5

    def __init__(self, config=None):
        super().__init__(config)
        self.bus = None
        self.client = None
        self.client_path = None
        self.on_location = None
        self.signal_id = None

    @staticmethod
    def is_available() -> bool:
        """True when geoclue2 can be reached on the system bus."""
        try:
            bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
            dbus = Gio.DBusProxy.new_sync(
                bus, Gio.DBusProxyFlags.NONE, None,
                "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", None,
            )
            for method in ("ListActivatableNames", "ListNames"):
                names = dbus.call_sync(method, None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
                if "org.freedesktop.GeoClue2" in names:
                    return True
            return False
        except GLib.Error as err:
            logging.debug("GeoclueLocationProvider: unavailable: %s", err)
            return False

    def _read(self, path) -> Optional[Dict[str, Any]]:
        """Turn one geoclue Location object into the dict the HAL expects."""
        location = Gio.DBusProxy.new_sync(
            self.bus, Gio.DBusProxyFlags.NONE, None,
            "org.freedesktop.GeoClue2", path, "org.freedesktop.GeoClue2.Location", None,
        )

        def number(name):
            value = location.get_cached_property(name)
            return None if value is None else value.get_double()

        latitude, longitude = number("Latitude"), number("Longitude")
        if latitude is None or longitude is None:
            return None

        fix = {
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": int(GLib.get_real_time() / 1000),
        }
        for key, name in (("altitude", "Altitude"), ("accuracy", "Accuracy"),
                          ("speed", "Speed"), ("bearing", "Heading")):
            value = number(name)
            if value is not None and value != UNSET and value >= 0:
                fix[key] = value
        return fix

    def _on_signal(self, _proxy, _sender, name, params):
        """Forward each geoclue LocationUpdated on to the HAL."""
        if name != "LocationUpdated" or self.on_location is None:
            return
        try:
            fix = self._read(params.unpack()[1])
            if fix:
                self.on_location(fix)
        except (GLib.Error, AttributeError, IndexError) as err:
            logging.warning("GeoclueLocationProvider: bad update: %s", err)

    def start(self,
              on_location: Callable[[Dict[str, Any]], None],
              on_nmea: Optional[Callable[[int, str], None]] = None,
              on_satellites: Optional[Callable[[list], None]] = None) -> bool:
        """Ask geoclue for a client and subscribe to its fixes."""
        self.on_location = on_location
        try:
            self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
            manager = Gio.DBusProxy.new_sync(
                self.bus, Gio.DBusProxyFlags.NONE, None,
                "org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager",
                "org.freedesktop.GeoClue2.Manager", None,
            )
            self.client_path = manager.call_sync(
                "GetClient", None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]

            props = Gio.DBusProxy.new_sync(
                self.bus, Gio.DBusProxyFlags.NONE, None,
                "org.freedesktop.GeoClue2", self.client_path, "org.freedesktop.DBus.Properties", None,
            )
            for key, value in (("DesktopId", GLib.Variant("s", self.DESKTOP_ID)),
                               ("RequestedAccuracyLevel", GLib.Variant("u", self.ACCURACY_EXACT)),
                               ("DistanceThreshold", GLib.Variant("u", self.DISTANCE_THRESHOLD))):
                props.call_sync(
                    "Set", GLib.Variant("(ssv)", ("org.freedesktop.GeoClue2.Client", key, value)),
                    Gio.DBusCallFlags.NONE, -1, None)

            self.client = Gio.DBusProxy.new_sync(
                self.bus, Gio.DBusProxyFlags.NONE, None,
                "org.freedesktop.GeoClue2", self.client_path, "org.freedesktop.GeoClue2.Client", None,
            )
            self.signal_id = self.client.connect("g-signal", self._on_signal)
            self.client.call_sync("Start", None, Gio.DBusCallFlags.NONE, -1, None)
        except GLib.Error as err:
            logging.error("GeoclueLocationProvider: cannot start: %s", err)
            return False

        logging.info("GeoclueLocationProvider: following geoclue on %s", self.client_path)

        # Geoclue only signals on change, so the fix it already holds would otherwise be withheld until the next move.
        try:
            current = self.client.get_cached_property("Location")
            if current is not None and current.get_string() not in ("", "/"):
                fix = self._read(current.get_string())
                if fix:
                    self.on_location(fix)
        except (GLib.Error, AttributeError) as err:
            logging.debug("GeoclueLocationProvider: no fix held yet: %s", err)
        return True

    def stop(self) -> None:
        """Release the geoclue client."""
        if self.client is not None:
            try:
                if self.signal_id is not None:
                    self.client.disconnect(self.signal_id)
                self.client.call_sync("Stop", None, Gio.DBusCallFlags.NONE, -1, None)
            except (GLib.Error, TypeError) as err:
                logging.debug("GeoclueLocationProvider: stop: %s", err)
        self.client = self.signal_id = self.on_location = None
