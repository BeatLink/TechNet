// Tang Server
//
// Panel toggle for tangd.socket. The icon follows the unit's real ActiveState over systemd's D-Bus API,
// and clicking starts or stops it. The polkit rule that ships with the tang module is what lets an
// unprivileged session call StartUnit and StopUnit for this one unit.

const Applet = imports.ui.applet;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;

const UUID = "tang@technet";
const UNIT = "tangd.socket";

const SYSTEMD_NAME = "org.freedesktop.systemd1";
const SYSTEMD_PATH = "/org/freedesktop/systemd1";
const MANAGER_IFACE = "org.freedesktop.systemd1.Manager";
const UNIT_IFACE = "org.freedesktop.systemd1.Unit";

const ICON_ACTIVE = "changes-allow-symbolic";
const ICON_INACTIVE = "changes-prevent-symbolic";
const ICON_ERROR = "dialog-error-symbolic";

class TangApplet extends Applet.IconApplet {

    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);
        this._manager = null;
        this._unit = null;
        this._unitChangedId = 0;
        this._show(ICON_ERROR, _("Tang: connecting to systemd"));
        this._connect();
    }

    // Builds the manager proxy, subscribes for unit signals and follows the unit's own properties.
    _connect() {
        try {
            this._manager = Gio.DBusProxy.new_for_bus_sync(
                Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, null,
                SYSTEMD_NAME, SYSTEMD_PATH, MANAGER_IFACE, null);
            this._subscribe();

            const loaded = this._manager.call_sync("LoadUnit",
                new GLib.Variant("(s)", [UNIT]), Gio.DBusCallFlags.NONE, -1, null);
            const path = loaded.deep_unpack()[0];

            this._unit = Gio.DBusProxy.new_for_bus_sync(
                Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, null,
                SYSTEMD_NAME, path, UNIT_IFACE, null);
            this._unitChangedId = this._unit.connect("g-properties-changed", () => this._refresh());
            this._refresh();
        } catch (error) {
            global.logError("[" + UUID + "] " + error);
            this._show(ICON_ERROR, _("Tang: cannot reach systemd"));
        }
    }

    // Asks systemd for unit signals on this connection, which fails harmlessly when something else already asked.
    _subscribe() {
        try {
            this._manager.call_sync("Subscribe", null, Gio.DBusCallFlags.NONE, -1, null);
        } catch (error) {
        }
    }

    // Reads the cached ActiveState and repaints the icon and tooltip from it.
    _refresh() {
        const state = this._activeState();
        if (state === "active" || state === "activating") {
            this._show(ICON_ACTIVE, _("Tang is serving keys. Click to stop."));
        } else {
            this._show(ICON_INACTIVE, _("Tang is stopped. Click to serve keys."));
        }
    }

    // Returns the unit's ActiveState, or "unknown" while the proxy has no cached value.
    _activeState() {
        if (!this._unit) return "unknown";
        const value = this._unit.get_cached_property("ActiveState");
        return value ? value.deep_unpack() : "unknown";
    }

    // Sets the panel icon and its tooltip together.
    _show(icon, tooltip) {
        this.set_applet_icon_symbolic_name(icon);
        this.set_applet_tooltip(tooltip);
    }

    on_applet_clicked() {
        if (!this._manager) return;
        const state = this._activeState();
        const method = (state === "active" || state === "activating") ? "StopUnit" : "StartUnit";
        this._manager.call(method, new GLib.Variant("(ss)", [UNIT, "replace"]),
            Gio.DBusCallFlags.NONE, -1, null, (proxy, result) => {
                try {
                    proxy.call_finish(result);
                } catch (error) {
                    global.logError("[" + UUID + "] " + error);
                    this._show(ICON_ERROR, _("Tang: the systemd call failed"));
                }
            });
    }

    on_applet_removed_from_panel() {
        if (this._unitChangedId) {
            this._unit.disconnect(this._unitChangedId);
            this._unitChangedId = 0;
        }
        this._unit = null;
        this._manager = null;
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new TangApplet(orientation, panelHeight, instanceId);
}
