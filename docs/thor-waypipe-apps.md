# Thor — which of Odin's apps to forward over waypipe

A survey of everything installed on Odin, judged on whether it is worth a
launcher on Thor. The mechanism is described in
[`waypipe.nix`](../nix/0-common/4-apps/technet/waypipe.nix); the launchers live
in [`5-phone/3-apps/desktop`](../nix/5-phone/3-apps/desktop) and the state they
keep on Odin's side is in
[`phone-apps.nix`](../nix/3-laptop/4-apps/technet/phone-apps.nix).

Three things decide the verdict for any given app:

* **Does it survive a 720-wide portrait window?** Anything built around a wide
  toolbar or a hover-dependent canvas does not.
* **Can a second instance run beside Odin's own?** Each waypipe session gets its
  own dbus-daemon, so a plain GtkApplication id collides with nothing. Anything
  holding a lock on a profile, a data directory or a socket needs one of its own.
* **How much does it push down the link?** `--video` is disabled in this tree's
  waypipe build, so every frame crosses as zstd-compressed raw. Games and
  realtime audio work are out.

## Forwarded

| App | Second instance by | State on Odin |
| --- | --- | --- |
| Firefox | `--profile` path outside `profiles.ini` | `/Storage/PhoneApps/Firefox/Thor` |
| Home Assistant | Firefox kiosk on its own profile | `…/Firefox/Thor/Kiosk` |
| KeePassXC | `--config` of its own, tray disabled | `…/KeePassXC/Thor` |
| Trilium | `TRILIUM_ELECTRON_DATA_DIR`, own port | `…/Trilium/Thor` |
| FreeTube | `--user-data-dir`, three dbs symlinked to Odin's | `…/FreeTube/Thor` |
| VSCodium | `--user-data-dir`, in-window file picker | `…/VSCodium/Thor` |
| VLC | separate dbus name | — |
| Pix, XViewer | separate dbus name, opened on a library path | — |
| Thunderbird | `--profile` path outside `profiles.ini` | `…/Thunderbird/Thor` |
| Element | `--profile-dir` | `…/Element/Thor` |
| Discord | `--user-data-dir` | `…/Discord/Thor` |
| NewsFlash | separate dbus name, shares Odin's sqlite | — |
| Quod Libet | `QUODLIBET_USERDIR`, moving its control socket | `…/QuodLibet/Thor` |
| XReader | separate dbus name | — |
| LibreOffice | `-env:UserInstallation` | `…/LibreOffice/Thor` |

The last seven rows are what this document was written to justify. Each starts
from an empty state directory: Thunderbird wants a profile copied out of Odin's
`~/.thunderbird`, Element and Discord each sign in as a second device, and Quod
Libet rescans the music on Odin's pool on first run.

## Worth adding later

Useful, but each carries a catch that has not been paid yet.

* **Vantage**, **Lenovo Control Center** — fan curves and charge thresholds
  read from the couch. They control Odin's hardware, so the phone becomes a
  remote for the laptop rather than a device of its own.
* **Mission Center** — watching Odin's load remotely is the case waypipe is
  best at, and it costs a whole session for a graph.
* **Vorta** — checking backup state away from the desk. Qt, so it wants
  `QT_QPA_PLATFORM` rather than `GDK_BACKEND`.
* **Anki** — reviewing on the phone is the obvious use, but its collection is a
  single-writer sqlite file and a second profile would split the review history.
* **Claude Desktop** — Electron, so it needs its own data dir and
  `NIXOS_OZONE_WL`, per the same pattern as FreeTube.
* **Simple Scan** — the scanner is physically on Odin, so driving it from the
  phone is a genuine win rather than a workaround.
* **SQLiteBrowser**, **Video Downloader**, **Baobab**, **Czkawka** — all fine
  technically; the grids are wide and the need is occasional.
* **Picard** — tagging is a wide-table workflow and painful in portrait.
* **Drawio**, **Inkscape** — canvas apps with dense toolbars and hover-dependent
  UI. Touch input over waypipe fights them.
* **virt-manager** — a VM console nested inside waypipe is two layers of remote
  framebuffer.

## Not worth forwarding

* **Steam**, **Lutris**, **itch**, **CKAN** — GPU-bound and gamescope-wrapped,
  against a link that carries raw frames.
* **LMMS** — realtime audio over a round trip that has swung between 65ms and
  334ms.
* **GParted**, **Ventoy** — destructive disk tools acting on Odin's hardware,
  driven from a phone.
* **Cheese** — would show Odin's webcam; Thor has a
  [native camera app](../nix/5-phone/3-apps/native/camera.nix).
* **GNOME Calculator** — adapts perfectly, and costs a whole waypipe session.
  Better installed natively on Thor.
* **Variety**, **Context**, **gnome-screenshot**, **app-separators**,
  **wmctrl**, **gallery-dl**, **gh** — desktop components or CLI tools, not
  standalone windows.
* **Xed** — Thor already runs it
  [natively](../nix/5-phone/3-apps/native/xed.nix).
* **WhatsApp** — that module only persists desktop files; there is no packaged
  app to launch.
