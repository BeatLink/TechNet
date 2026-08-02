# Cinnamon parity report

What the Cinnamon session on `Odin` has that the Hyprland session and Context do
not, as of 2026-08-01.

## Scope and method

Three sources were read:

- The exported dconf in
  [nix/3-laptop/1-system/18-desktop-environment/cinnamon/dconf/](nix/3-laptop/1-system/18-desktop-environment/cinnamon/dconf/) —
  `org.cinnamon`, `org.gnome.desktop`, `org.gtk.settings`, `org.x.apps`.
  These are loaded by the generic dconf importer in
  [17-dconf/dconf-options.nix](nix/3-laptop/1-system/17-dconf/dconf-options.nix).
- The per-applet settings in `~/.config/cinnamon/spices/`, which are **not** in
  this repo — dconf records only which applets are enabled and where, never how
  they are configured. Everything in the "how it is set up" column below comes
  from there.
- Every module under
  [18-desktop-environment/hyprland/](nix/3-laptop/1-system/18-desktop-environment/hyprland/),
  plus Context's own README and roadmap.

The live `org/cinnamon/enabled-applets`, `enabled-extensions` and
`enabled-desklets` were compared against the repo copies and match, so the
exported dconf is current.

Legend: **✅** equivalent exists · **◐** partly covered, something is lost ·
**✗** nothing on the Hyprland side.

---

## Summary

| | Count |
| --- | --- |
| Applets fully replaced | 5 |
| Applets partly replaced | 6 |
| Applets with no replacement | 9 |
| dconf setting groups fully mapped | 11 |
| dconf setting groups partly or not mapped | 9 |

The single largest category is **panel indicators that were menus**. Waybar
modules display a value; the Cinnamon applets they replaced opened a menu you
could act in — pick a Wi-Fi network, change a power profile, scrub a track,
clear a print queue. That interaction is what is missing, not the reading.

The second is **runtime configurability**: Cinnamon Settings changes keybinds,
panel contents, applets and themes while the session runs. Every equivalent here
is a rebuild.

---

## Panel layout

Cinnamon runs **two** panels, both 48px:

| Panel | Position | Autohide | Contents |
| --- | --- | --- | --- |
| `panel1` | top | never | menu, Direct, weather, calendar, timer, 2× trilium-api, and 12 status applets on the right |
| `panel2` | bottom | `intel` (intelligent) | `grouped-window-list` only |

Icon and text sizes are set per zone: panel 1 uses 16px icons and 12px text
throughout; panel 2 uses 32px icons on the left and 48px in the centre with no
text — the bottom panel is a dock, not a bar.

The Hyprland session has **one** bar, along the top, 40px, no autohide, no
bottom panel. The window list that was `panel2` is now Context's sidebar, which
is a deliberate replacement rather than a gap — but the two are not the same
thing (see `grouped-window-list` below).

`no-adjacent-panel-barriers=true` and `panels-hide-delay`/`show-delay` of 0 have
no waybar equivalent; waybar has no autohide at all.

---

## Applets

### Fully replaced

| Applet | What it does | Replacement |
| --- | --- | --- |
| ✅ `menu@cinnamon.org` | Applications menu, opened on Super. Configured lean: no sidebar, no avatar, no places, no favourites, no recents, no descriptions; search box at the bottom; 22px icons | Context's overview, bound to `bindr SUPER, SUPER_L` in [hotkeys.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/hotkeys.nix#L29). Richer than the menu was — the menu had every optional section switched off, so it was a category list and a search box, which is exactly what the overview is |
| ✅ `notifications@cinnamon.org` | Notification history, count badge, `Super+N` to open | swaync ([notifications.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/notifications.nix)), same `$mod+N` binding. See the partial note on the count badge below |
| ✅ `transparent-panels@germanfr` (extension) | `panel-semi-transparent` on all four edges | waybar's `rgba(surface, 0.75)` in [waybar.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/waybar.nix#L148) |
| ✅ `inhibit@cinnamon.org` | A menu with two switches — "Power management" (a GNOME SessionManager inhibitor) and "Notifications" (`display-notifications`) — plus a list of apps currently inhibiting. Both keybindings (`keyPower`, `keyNotifications`) are empty, so none to port | waybar `idle_inhibitor` is the power switch, `custom/dnd` is the notifications switch, adjacent in the bar. Tooltips reuse the applet's own wording. **Not ported:** the applet drew one icon for both states and listed which apps hold an inhibitor; waybar has no way to feed that list into a built-in module's tooltip |
| ✅ `weather@mockturtl` | Weather, OpenMeteo at 18.0028,-76.7897 | [scripts.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/scripts.nix) reimplements it against the same provider and coordinates — see the partial note below |

### Partly replaced

| Applet | How it is set up | What survives | What is lost |
| --- | --- | --- | --- |
| ◐ `weather@mockturtl` | 3-day forecast, 24 hourly entries, 4×4 forecast grid, alerts on, sunrise/sunset on, UV index on, refresh every 15 min | Current condition and temperature in the bar; a tooltip with feels-like and humidity | **The forecast entirely.** No 3-day or hourly view, no weather alerts, no sunrise/sunset, no UV index. `hypr-weather` requests only `current=` from the API |
| ◐ `sound@cinnamon.org` | MPRIS player control on, known players include Firefox, VLC, QuodLibet, gmusicbrowser, Stremio; middle-click mutes output, middle-shift-click mutes input; `Shift+Super+S` opens it; systray hidden | waybar `pulseaudio` shows and scrolls volume, click opens pavucontrol. swaync's `mpris` widget has transport controls | Media controls are behind `$mod+N` (the notification centre) instead of one click on the bar. No per-app volume from the bar, no track title, no middle-click mute, `Shift+Super+S` unbound. waybar's scroll bypasses swayosd so it draws no OSD, unlike the media keys |
| ◐ `power@cinnamon.org` | `percentage_time` label, `showmulti` on — and `device-aliases` in dconf names five devices: internal battery, wireless keyboard, keyboard-and-mouse, and two headsets | waybar `battery` shows the internal battery percentage and time-to-empty | **Peripheral battery levels.** The keyboard, mouse and headset batteries that `showmulti` + `device-aliases` surfaced are not shown anywhere. waybar ships an `upower` module that does exactly this and is not in the bar. Also no brightness slider in the menu (the `backlight` module scrolls but has no popup) |
| ◐ `network@cinnamon.org` | `Shift+Super+N` to open | waybar `network` shows SSID and signal strength | **Choosing a network.** Clicking opens `nm-connection-editor`, which edits saved connections; it does not scan and list nearby Wi-Fi. Joining a new network from the bar is gone. `Shift+Super+N` unbound |
| ◐ `notifications@cinnamon.org` | `showNotificationCount` on, `Super+N` open, `Shift+Super+C` clear all | swaync history and popups. The `custom/dnd` module added for the inhibit applet feeds from `swaync-client -swb`, so **hovering it now reports the count** | The count is in a tooltip rather than on the bar face — the module shows do-not-disturb state, since that is what it was added for. Displaying the count is a one-line change to its `format`. `Shift+Super+C` (clear all) still unbound |
| ◐ `grouped-window-list@cinnamon.org` | The bottom panel. Grouped windows, hover thumbnails with peek (300ms in, 100% opacity), window-count badges, notification badges, `Super+`&#96; for app order, Super+number hotkeys, and **24 pinned launchers** organised into five groups by separator entries — Firefox/Trilium/KeePassXC/Nemo, then comms, then media, then terminal and editor | Context's sidebar lists what is running and switches between it | **Pinned launchers.** There is no dock: 24 apps that were one click away are now a search in the overview. Also no window thumbnails, no hover peek, no window-count or notification badges. Super+number launches the pinned app in Cinnamon; in Hyprland it switches workspace |

### No replacement

| Applet | What it does | Notes |
| --- | --- | --- |
| ✗ `cinnamon-sidebar@beatlink` | **Your own applet.** Docks any window to the left or right edge at a fixed width — currently right, 400px — reserves that strip so other windows never overlap it, keeps the docked window pinned, and makes maximise fill only the space beside it. `Super+Shift+Left` docks, `Super+Shift+Down` undocks | The closest thing on the Hyprland side is Context's own launcher, which reserves a strip for *itself*. Docking an arbitrary application window — a Trilium pane, a terminal — to the edge with reserved space is not something Context, hyprbars or a window rule currently does. Note `Super+Shift+Left` is now `$context window-left` |
| ✗ `trilium-api@beatlink` ×2 | **Your own applet.** Pulls text from a Trilium API script (`agenda_panel`, `get_task`) into the panel every 5s, click opens the task in Trilium. Reminder highlighting available (off on the live instance) | Nothing reads Trilium into the bar. It would be a waybar `custom/` module — the applet is 5s polling of one HTTP endpoint, so the port is small. **One of the two instances (id 145) has a blank endpoint and key**, so only one is actually displaying anything |
| ✗ `Direct@claudiux` | Places menu on the left of the panel, labelled "Files": home and user folders, computer/root/volumes/network, favourites, favourite apps, trash, and the 10 most recent documents — each with a settings shortcut | Nemo browses files but nothing surfaces bookmarks, mounted volumes or **recent documents** from the bar. `desktop/privacy remember-recent-files=true` with a 7-day age is still set, so the recent list is being maintained and nothing displays it |
| ✗ `cinnamon-timer@jake1164` | Countdown timer with presets from 10 minutes to 5 hours, a duration display in the panel, a confirmation prompt, an "Time up!" message and a sound from `/Storage/Files/Sounds/…/Daynew 2.wav` at 50% | Nothing. Context's roadmap item 10 is "Context timers", so this may land there rather than in the bar |
| ✗ `power-profiles@rcalixte` | Switches power-profiles-daemon between saver, balanced and performance, with an OSD on change | waybar **ships a `power-profiles-daemon` module** and it is not in the bar. This is the cheapest gap on the list to close |
| ✗ `nightlight@cinnamon.org` | Manual toggle for night light, independent of the schedule | hyprsunset applies the 21:00→06:00 / 2700K schedule ([night-light.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/night-light.nix)) but there is no way to turn it on or off by hand. `hyprctl hyprsunset identity` / `temperature 2700` would drive a `custom/` module |
| ✗ `printers@cinnamon.org` | `show-icon: jobs` — appears only when there is a print queue, and shows it | CUPS is enabled in [11-printing.nix](nix/3-laptop/1-system/11-printing.nix) but nothing reports queue state. A stuck job is now silent |
| ✗ `xapp-status@cinnamon.org` | Host for XApp status icons, the Mint-specific tray protocol | waybar's `tray` implements StatusNotifierItem only. Impact is probably low here — most of the tray-using apps installed (KeePassXC, Syncthing, Discord, Element, Vorta) use SNI — but any XApp-native indicator has nowhere to go |
| ✗ `systray@cinnamon.org` | Legacy XEmbed tray, for apps predating SNI | No XEmbed host under Wayland. XWayland apps that only do XEmbed lose their icon with no fallback |
| ✗ `show-hide-applets@mohammad-sn` | Collapses the right-hand applets behind a toggle after 2s, reopens on hover after 75ms | No equivalent, and arguably not needed — it existed to manage a right zone holding 12 applets, and waybar's right zone holds 7 |

### Installed but not enabled

Present in `~/.local/share/cinnamon/` and **not** in `enabled-applets` /
`enabled-extensions` / `enabled-desklets`, so out of scope but worth knowing
about before anything is ported: `auto-dark-light@gihaume`,
`gpaste-reloaded@feuerfuchs.eu`, `nvidia-monitor@kalin91`,
`pomodoro@gregfreeman.org`, `SpicesUpdate@claudiux`, `window-list@sangorys`,
`battery-guardian@beatlink` (your own extension — forced shutdown on critical
battery), `centered-cinnamon-dock@mostlynick3`, and the `notes@schorschii`
desklet.

`battery-guardian` is the interesting one: it is disabled, but
`critical-battery-action='suspend'` in dconf is what would fire instead, and the
Hyprland session has neither — hypridle has no battery-level listener.

---

## dconf settings

### Mapped

These are reproduced in the Hyprland modules, mostly with the dconf key named in
a comment beside them:

| Group | Where |
| --- | --- |
| `desktop/peripherals/keyboard` repeat delay/interval, numlock | [default.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/default.nix#L152-L167) |
| `desktop/peripherals/touchpad` tap, click-method, disable-while-typing | same |
| `desktop/interface` fonts, cursor theme, GTK/icon theme | same, plus [theme.nix](nix/3-laptop/1-system/18-desktop-environment/theme.nix) |
| `desktop/keybindings` — media keys, custom keybinds, wm binds | [hotkeys.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/hotkeys.nix) |
| `desktop/session` idle-delay, `settings-daemon/plugins/power` timeouts, `desktop/screensaver` | [screenlock.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/screenlock.nix) |
| `settings-daemon/plugins/color` night light | [night-light.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/night-light.nix) |
| `settings-daemon/plugins/power` lid-close actions | [lid.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/lid.nix) |
| `settings-daemon/plugins/xsettings` hinting, menu/button icons | [default.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/default.nix#L239-L244) |
| `hotcorner-layout` | [hot-corners.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/hot-corners.nix) |
| `gestures` (3- and 4-finger) | [gestures.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/gestures.nix) |
| `muffin` border width, modal dialogs, focus-on-activate | [default.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/default.nix#L106-L182) |

`org.gtk.settings`, `org.gnome.desktop` and `org.x.apps` are loaded by the dconf
importer as `WantedBy=default.target`, so they apply in **both** sessions — the
file chooser preferences, GTK colour palette and portal colour scheme carry over
without any Hyprland-side work.

### Partly mapped or unmapped

| Setting | Value | Status |
| --- | --- | --- |
| `sounds/*` | 13 events with sound files | ◐ Only `map`/`close`/`maximize`/`minimize`/`unmaximize`/login/logout are reproduced. **`plug`/`unplug` (device connect), `switch` (workspace) and `tile` are not** — documented as deliberate in [sounds.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/sounds.nix) |
| `desktop/sound volume-sound-enabled` | `true`, with a wav | ✗ **Not reproduced.** Changing the volume plays a sound in Cinnamon; swayosd draws the popup but plays nothing |
| `desktop/a11y/keyboard togglekeys-enable-beep` | `true`, with a wav | ✗ Caps/num lock plays a sound in Cinnamon. swayosd covers `togglekeys-enable-osd` but not the beep |
| `settings-daemon/plugins/power button-power` | `interactive` | ✗ **No `HandlePowerKey` override anywhere**, so logind's default applies and the power button powers off immediately instead of asking |
| `cinnamon-session quit-delay-toggle` / `quit-time-delay` | `true` / 5s | ✗ No logout dialog and no countdown. `$mod+Shift+Q` exits Hyprland outright |
| `settings-daemon/plugins/power critical-battery-action` | `suspend` | ✗ hypridle has no battery listener. Nothing acts on a critical battery |
| `desktop/media-handling autorun-never` | `false` | ✗ No autorun prompt on inserting removable media. gvfs is enabled so Nemo can mount, but nothing offers |
| `alttab-switcher-style` | `icons+preview`, 100ms delay | ✗ **No visual Alt+Tab.** `cyclenext` switches blind. Context's `switch-window` is a list picker, not a preview switcher — a different interaction |
| `desktop/peripherals/mouse middle-click-emulation` | `true` | ✗ Not set on the Hyprland input block |
| `desktop/interface cursor-blink-time` | 720 | ✗ Not in `gtk3.extraConfig` |
| `desktop/interface gtk-overlay-scrollbars` | `true` | ✗ Not in `gtk3.extraConfig` |
| `launcher check-frequency` / `memory-limit` | 60s / 1024MB | ✗ Cinnamon restarts its own shell if it leaks. Nothing watches the Hyprland components — closest is the `Restart=on-failure` on each user service |
| `desktop/applications/calculator` + `media-keys terminal` | `Calculator` key opens the terminal | ✗ `XF86Calculator` unbound |
| `desktop/wm/preferences button-layout` | `:minimize,maximize,close` | ◐ hyprbars gives close, maximise and move-to-context. **No minimise**, documented as deliberate in [window-controls.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/window-controls.nix#L41-L50) |
| `muffin placement-mode` | `center` | ◐ Only floating windows are centred, via a window rule |
| `muffin min-window-opacity` | 30 | ✗ Noted as deliberately dropped |
| `gestures swipe-*-2` | `PUSH_TILE_*` | ✗ Deliberate — two-finger swipes are left to scrolling |
| `desktop/a11y/*` | mouse keys, slow keys, bounce keys, dwell click, screen reader, on-screen keyboard | ◐ All currently **off** in Cinnamon, so nothing is lost today — but there is no accessibility daemon in the Hyprland session at all, so none of them could be turned on |

---

## Keybindings

Applet shortcuts that were bound in Cinnamon and are not bound under Hyprland:

| Key | Was | Under Hyprland |
| --- | --- | --- |
| `Super+C` | Calendar applet | Unbound (`$mod+C` is Context hard restart) |
| `Shift+Super+S` | Sound applet | Unbound (`$mod+Shift+S` is screenshot area) |
| `Shift+Super+N` | Network applet | Unbound |
| `Shift+Super+W` | Weather applet | Unbound (`$mod+Shift+W` is `switch-window-all`) |
| `Shift+Super+C` | Clear all notifications | Unbound (`$mod+Shift+C` is `context capture`) |
| `Super+`&#96; | Grouped window list app order | Rebound to `context switch-window-all` |
| `Super+Shift+Left` | `cinnamon-sidebar` dock a window | Rebound to `context window-left` |
| `Super+Shift+Down` | `cinnamon-sidebar` undock | Unbound |
| `Super_R` | Opens the menu (`overlay-key` is `Super_L::Super_R`) | Only `SUPER_L` is bound |

Five of the nine are cases where the Hyprland session has taken the key for
something else, so they cannot simply be added back — the applet functions they
belonged to would need different keys.

---

## Structural gaps

Things that are not one setting, and would not be fixed by porting one applet.

**No settings GUI.** Cinnamon Settings changes displays, keyboard shortcuts,
themes, applets, startup applications, mouse behaviour and sound while the
session runs. The Hyprland session has `wdisplays`, `pavucontrol`, `blueman` and
`nm-connection-editor` — four single-purpose tools — and everything else is a
rebuild. Context's settings screen covers Context; nothing covers the
compositor.

**No panel edit mode.** Cinnamon's `panel-edit-mode` lets applets be dragged
between zones and panels added or removed live. Waybar's contents are in
[waybar.nix](nix/3-laptop/1-system/18-desktop-environment/hyprland/waybar.nix)
and change on rebuild.

**No add-on ecosystem.** `cinnamon-spice-updater` runs as a user service and
keeps 13 installed applets current. Three of those are yours
(`cinnamon-sidebar`, `trilium-api`, `battery-guardian`) — the Cinnamon spice
format gave you a place to write small desktop extensions in JS with a settings
schema and a GUI for it. Waybar's `custom/` modules are the equivalent for the
bar and cover less: a script, stdout, and no settings UI.

**No desktop widgets.** `enabled-desklets` is empty, so nothing is lost today,
but the capability is gone (`notes@schorschii` is installed and disabled).

**The dock is gone, not moved.** Worth stating plainly because it is easy to
read Context's sidebar as replacing `grouped-window-list`: the sidebar replaces
the *window list* half of that applet. The *pinned launcher* half — 24 apps in
five separator-delimited groups, always visible along the bottom — has no
successor. In Context the equivalent act is opening the overview and typing.

---

## Ranked recommendations

Cheapest first, by effort against what it restores.

1. **Add waybar's `power-profiles-daemon` module.** One block. Restores an
   applet outright.
2. **Add waybar's `upower` module.** Restores the peripheral battery levels the
   `device-aliases` in dconf were naming.
3. ~~Add a `custom/notification` module driven by `swaync-client -swb`.~~
   **Done** as `custom/dnd`, for the inhibit applet's notifications switch. The
   count is in its tooltip; put `{}` in its `format` to show it on the bar face.
4. **Add a `custom/nightlight` module** driven by `hyprctl hyprsunset`. hyprsunset
   is already running; this is only a toggle over it.
5. **Set `HandlePowerKey`**, or bind the power key to a confirmation menu, so the
   power button stops being an immediate poweroff.
6. **Install `nm-applet`** (already in `home.packages` via
   `networkmanagerapplet`) and run it, or point the network module at a Wi-Fi
   picker, so joining a network does not need the connection editor.
7. **Extend `hypr-weather`** to request the forecast as well as `current=`, and
   put it in the tooltip. The applet's 3-day and hourly views are the biggest
   single loss among the "partly replaced" set.
8. **Play the volume sound** in the swayosd bindings, and the togglekeys beep —
   `paplay` calls next to the existing `swayosd-client` ones.
9. **Add a battery-level listener** for `critical-battery-action=suspend`, since
   neither the dconf action nor `battery-guardian` applies here.
10. **Port `trilium-api` to a `custom/` module.** 5s polling of one endpoint,
    click to open — small, and it is your own applet, so nothing else will do it.
11. **Decide about the dock.** Either accept the overview as the answer, add a
    waybar `wlr/taskbar` with the pinned list, or make it a Context feature. This
    is the one that changes daily use most and has no obvious cheap fix.
12. **Decide about `cinnamon-sidebar`.** Docking an arbitrary window to an edge
    with reserved space is a real capability with no Hyprland analogue. It is
    plausibly a Context feature — Context already reserves an edge strip and
    already places windows — rather than a compositor plugin.

Items with no cheap answer, listed so they are not mistaken for oversights: the
visual Alt+Tab switcher, the print queue indicator, XEmbed and XApp tray icons,
the logout countdown, the media autorun prompt, and any accessibility feature.
