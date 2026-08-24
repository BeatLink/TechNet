// Cinnamon can only set a window above the others by hand, per window, per launch, and forgets on close.
// This applies that same state to every window of the classes below, as they appear.

const CLASSES = ["org.keepassxc.keepassxc", "keepassxc"];

let displayId = 0;
const watched = new Map();

// Puts the window above the others when its class is one of ours.
function raise(metaWindow) {
    const wmClass = metaWindow.get_wm_class();
    if (wmClass && CLASSES.indexOf(wmClass.toLowerCase()) !== -1) metaWindow.make_above();
}

// Applies the rule now and again on any class change, since a Wayland toplevel gets its app id after it exists.
function watch(metaWindow) {
    if (watched.has(metaWindow)) return;
    raise(metaWindow);
    watched.set(metaWindow, [
        metaWindow.connect("notify::wm-class", raise),
        metaWindow.connect("unmanaged", forget),
    ]);
}

// Releases a window's handlers, on close or when the extension stops.
function forget(metaWindow) {
    const handlerIds = watched.get(metaWindow);
    if (!handlerIds) return;
    handlerIds.forEach((handlerId) => metaWindow.disconnect(handlerId));
    watched.delete(metaWindow);
}

function init(metadata) {}

function enable() {
    displayId = global.display.connect("window-created", (display, metaWindow) => watch(metaWindow));
    global.get_window_actors().forEach((actor) => watch(actor.meta_window));
}

function disable() {
    global.display.disconnect(displayId);
    displayId = 0;
    Array.from(watched.keys()).forEach(forget);
}
