# Thor — Firefox tuning

Everything here is specific to running Firefox on a 2972MB, 1.15GHz A53 phone
with a Mali-400 that no browser on this device can use. The reasoning behind the
device-level numbers is in
[`performance.nix`](../nix/5-phone/1-system/performance.nix) and
[`webkit.nix`](../nix/5-phone/1-system/webkit.nix); this file only covers
the browser.

Verified against Firefox **153.0.3**.

## What the package already gives you

`pkgs.firefox-mobile` is not a plain Firefox. It is postmarketOS'
[mobile-config-firefox](https://gitlab.postmarketos.org/postmarketOS/mobile-config-firefox)
4.6.0 applied through `wrapFirefox`, and it brings three things that are easy to
duplicate by accident:

* **`policies.json`** — `DisableTelemetry`, `DisableFirefoxStudies`,
  `DisablePocket`, `FirefoxHome.TopSites: false`, DuckDuckGo as default, and an
  automatic install of uBlock Origin from AMO — the last of which we now
  override with a pinned local XPI.
* **`mobile-config-autoconfig.js`** — touch density, pinch and double-tap zoom,
  a mobile user agent with per-site overrides, hidden titlebar, blank new tab,
  no search suggestions, and the userChrome/userContent CSS.
* **`mobile-config-prefs.js`** — `browser.uidensity`.

Ordering matters and works in our favour: the wrapper concatenates
`extraPrefsFiles` into `mozilla.cfg` first and `extraPrefs` last, so anything set
in [`firefox.nix`](../nix/5-phone/3-apps/core/firefox.nix) wins over
mobile-config.

Two prefs mobile-config sets no longer exist in 153 —
`toolkit.cosmeticAnimations.enabled` and `browser.download.animateNotifications`.
Both are upstream, not ours. `ui.prefersReducedMotion` covers the same ground and
reaches site CSS as well as browser chrome.

## Build-level: nothing left to win

Checked so it does not get re-investigated:

| | |
| --- | --- |
| PGO | **on** — `pgoSupport` needs `hostPlatform == buildPlatform`, and building aarch64 under binfmt on Odin satisfies that. It is a native build in a slow emulator, not a cross-compile. |
| LTO | **on** — enabled for 64-bit Linux, which includes `aarch64-linux`. |
| Wayland | **on** — the nixpkgs wrapper sets `MOZ_ENABLE_WAYLAND=1`, so no XWayland. |
| Updater | **compiled out** — `--disable-updater`, confirmed by `MOZ_UPDATER: false` in `AppConstants.sys.mjs` and no `updater` binary in the package. Every `app.update.*` pref is inert. |

The only build knobs left are subtractive and appear in the tiers below:
`crashreporterSupport = false` and `webrtcSupport = false`.

## Dead prefs

Removed from [`firefox.nix`](../nix/5-phone/3-apps/core/firefox.nix) because the
pref no longer exists in 153. Kept here so they do not get pasted back from an
old about:config guide.

| Dead pref | Replacement |
| --- | --- |
| `gfx.webrender.enabled` | none — WebRender is mandatory since 93. `gfx.webrender.software` is the only remaining choice. |
| `layers.acceleration.disabled` | none — pre-WebRender compositor knob. `gfx.canvas.accelerated = false` is the nearest live equivalent. |
| `extensions.pocket.enabled` | the `browser.newtabpage.activity-stream.*` stories and sponsored prefs. Save-to-Pocket was removed; the newtab feed inherited the name. |
| `app.update.enabled` | `app.update.auto`, or the `DisableAppUpdate` policy. |
| `dom.ipc.keepProcessesAlive.web` | none. |

## Verifying a pref still exists

Worth redoing after a Firefox bump, because dead prefs fail silently — Firefox
accepts any name in `mozilla.cfg` and simply never reads it.

Static prefs live in `libxul.so`'s string table; the rest are in `greprefs.js`
inside `omni.ja` and `defaults/preferences/firefox.js` inside `browser/omni.ja`.
Note that `omni.ja` is a zip with a non-standard central directory, so Python's
`zipfile` refuses it — scan for `PK\x03\x04` local headers and inflate each entry
by hand. The `browser.newtabpage.activity-stream.*` set is a third case: those
register by suffix in Activity Stream's `PREFS_CONFIG` map, so search for both
the full name and the part after `activity-stream.`.

## Applied

Currently in [`firefox.nix`](../nix/5-phone/3-apps/core/firefox.nix). All 44
pref names confirmed live in 153.0.3.

* Software rendering forced, canvas acceleration and WebGL off
* `layout.frame_rate` at 30, smooth scroll off, `ui.prefersReducedMotion`
* Fission off, 2 content processes, no prelaunched spare, a11y forced off
* Tab unloading with a 10% available-memory trigger, session history and undo
  trimmed, image surface cache capped at 64MB
* No disk cache, 32MB memory cache, 5-minute session store interval
* Autoplay blocked, hardware decode probe off, media cache capped
* Prefetch, speculative connections and DNS prefetch off
* Local ML features off (`browser.ml.enable`, smart tab groups)
* Pocket-descended newtab feeds and sponsored content off
* Extension and search-engine update checking off
* uBlock Origin pinned to a Nix-fetched signed XPI instead of AMO's `latest`
* Normandy, region lookup, discovery, UITour, welcome and addon recommendations
  off; telemetry off at the subsystem level, not just upload
* Newtab preload and tab warmup off
* Crash reporter off via `MOZ_CRASHREPORTER_DISABLE`

**`fission.autostart = false` is the one to revisit first.** It is the largest
memory win available and the only line in the file that gives up a security
property — Spectre-grade site isolation.

## Backlog

Ordered by how much you lose, not by how much you gain. Everything is verified
to exist in 153.0.3; none of it is measured on this board.

### Tier 0 — no feature loss

- [ ] **Move the profile off the SD card.**
      [`firefox.nix`](../nix/5-phone/3-apps/core/firefox.nix) persists it to
      `/Storage/Apps/Core/Firefox` on the card, at a measured 3028 µs/file
      against the eMMC's 1288 µs. The profile is thousands of small sqlite and
      cache files. Costs eMMC space and nothing else.

      **prewarm covers about half of this, and only the read half.**
      `services.prewarm.profiles.firefox.dirs` becomes `PREWARM_WARM_DIRS`,
      which `prewarm warm` walks with `warm_dir()` — it opens and reads each
      file into page cache and stops there. The mlock path is a different one:
      `prewarm lock` reads only `PREWARM_PROFILE_DIRS`, the recorded `.pages`
      regions, and those are confined to `PREWARM_PREFIX=/nix/store`. So the
      profile is warmed on a timer but never pinned, and on a phone this tight
      unpinned cache is the first thing dropped.

      Nothing in prewarm touches **writes**, which is the half the card is worst
      at — `places.sqlite`, `cookies.sqlite`, `favicons.sqlite` and session
      store, all landing on SD with its write amplification. That is the same
      concern `zfs_txg_timeout=15` and the 5-minute `browser.sessionstore.interval`
      already exist to blunt.
- [ ] **ZFS properties on the dataset holding the profile.** `atime=off` drops a
      metadata write per file read, `recordsize=32K` matches Firefox's sqlite
      page size so a page update rewrites one record rather than a 128K block,
      `logbias=throughput` keeps sqlite's syncs out of the ZIL.
- [x] ~~Lock `libxul.so` in
      [`prewarm.nix`](../nix/5-phone/1-system/prewarm.nix).~~ **Already
      covered, and adding it explicitly would make things worse.**

      prewarm's watcher runs with `PREWARM_PREFIX=/nix/store`, and
      `prewarm watch` records *the pages processes actually touched*, ageing out
      what stops being used. `libxul.so` is in the store, so its hot pages are
      already recorded from every running Firefox and mlocked by
      `prewarm lock`, up to the ceiling.

      `profiles.<name>.dirs` is a different mechanism — it becomes
      `PREWARM_WARM_DIRS`, which warms whole directories, and exists for the
      profile paths *outside* the store that the page recorder never sees. Put
      the Firefox lib directory there and you ask for all of `libxul.so`:

      | | |
      | --- | --- |
      | `libxul.so`, aarch64 | 239,904,776 B — 228.8 MiB |
      | `maxLocked` | 402,653,184 B — 384 MiB |

      That is 60% of the budget spent on one file, most of it code paths never
      executed, and per the comment in that file overrunning the ceiling drops
      pages by path order rather than by usefulness — so it would evict the
      profile dirs that are working today.
- [x] **`MemoryHigh` on `app.slice`**, in
      [`performance.nix`](../nix/5-phone/1-system/performance.nix) next to
      the phosh block it complements. phosh has `MemoryMin`/`MemoryLow` and
      [`focus-boost.nix`](../nix/5-phone/1-system/focus-boost.nix) handles
      CPU and IO priority; the gap was the other direction — nothing made an app
      reclaim before the session got reclaimed out from under it.

      **On the slice, not on Firefox's own unit.** App units here are transient
      and D-Bus-named (`app-dbus\x2d:1.2\x2d….slice`), so there is no stable name
      to write a drop-in against — focus-boost matches them by heuristic at
      runtime for exactly that reason, and a static memory ceiling should not
      depend on a heuristic. `app.slice` is name-independent and always applies.
      It covers Waydroid and Epiphany too, which can do the same damage.

      1800M is deliberately generous. It is a backstop against runaway growth,
      not a routine throttle: reclaim costs CPU, and CPU is the scarce resource
      here (pressure in the sixties against io at 3.44), so a ceiling tight
      enough to bind during normal browsing would cost more than it saves.
      `MemoryMax` is the wrong knob — it OOM-kills rather than throttling.
- [x] **Crash reporter off** via `environment.sessionVariables`.
      `MOZ_CRASHREPORTER_DISABLE` is present in the aarch64 `libxul.so`, so the
      runtime switch works.

      **Do not use `crashreporterSupport = false`.** It rebuilds
      `firefox-unwrapped` from source, which means aarch64 under binfmt on Odin
      — megi's kernel is roughly 13 hours that way, and Firefox is far larger,
      with PGO adding an instrumented build plus a profiling run under `xvfb`,
      also emulated. It also forfeits the cache.nixos.org substitute on every
      subsequent Firefox bump. The env var costs nothing and keeps the binary
      cache.

      Verify after deploying with `pgrep -a crashhelper` — 153 ships a
      `crashhelper` binary alongside `crashreporter`.
- [x] Update checking. `app.update.*` is **not** worth setting — nixpkgs builds
      with `--disable-updater`, so `MOZ_UPDATER` is false, there is no `updater`
      binary, and the update service is never registered. Only extension and
      search-engine updates are live:
      ```
      pref("extensions.update.enabled", false);
      pref("extensions.update.autoUpdateDefault", false);
      pref("browser.search.update", false);
      ```
      uBlock Origin is pinned in Nix rather than pulled from AMO, so this costs
      nothing — see below.
- [x] **Pin uBlock Origin in Nix.** mobile-config installs it via an
      `ExtensionSettings` policy pointing at AMO's `latest.xpi`, which means the
      version is whatever AMO served on first run and Firefox owns the updates.
      [`firefox.nix`](../nix/5-phone/3-apps/core/firefox.nix) now overrides that
      policy entry with a `file://` store path.

      Two things make this the only workable shape:

      * **`nixExtensions` cannot be used.** The wrapper throws unless
        `requireSigning` is false and `allowAddonSideload` is true — LibreWolf,
        not stock Firefox.
      * **`fetchFirefoxAddon` cannot be used either.** It unzips the XPI,
        rewrites `manifest.json` to inject an extid, and re-zips, which
        invalidates `META-INF/mozilla.rsa`. Stock Firefox then refuses it. Plain
        `fetchurl` keeps the AMO signature intact.

      The `jq -s '.[0] * .[1]'` merge in the wrapper puts `extraPolicies` on the
      right, so our entry wins over mobile-config's. Verified in the built
      wrapper's `distribution/policies.json`, and the XPI is in the runtime
      closure.

      To bump: query
      `https://addons.mozilla.org/api/v5/addons/addon/ublock-origin/` for
      `current_version.file.url`, then `nix store prefetch-file` it for the SRI
      hash.
- [x] Background services with no user-visible function here:
      ```
      pref("app.normandy.enabled", false);
      pref("datareporting.policy.dataSubmissionEnabled", false);
      pref("toolkit.telemetry.unified", false);
      pref("toolkit.telemetry.archive.enabled", false);
      pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
      pref("browser.region.update.enabled", false);
      pref("browser.discovery.enabled", false);
      pref("browser.uitour.enabled", false);
      pref("browser.aboutwelcome.enabled", false);
      pref("extensions.getAddons.showPane", false);
      pref("extensions.htmlaboutaddons.recommendations.enabled", false);
      ```
- [x] Preloads. `browser.newtab.preload` keeps an entire preloaded browser
      element in memory for a page mobile-config already blanked;
      `browser.tabs.remote.warmup.enabled` spins up a content process on tab
      hover, which a touchscreen barely triggers. `dom.ipc.processPrelaunch` was
      already off:
      ```
      pref("browser.newtab.preload", false);
      pref("browser.tabs.remote.warmup.enabled", false);
      ```
- [ ] Remaining mouse-only or console-only UI:
      ```
      pref("browser.tabs.hoverPreview.enabled", false);
      pref("layout.css.report_errors", false);
      ```

### Tier 1 — loss you will not notice on this device

- [ ] Local history embeddings, urlbar suggestions, connection limits, decode
      chunk size and history retention:
      ```
      pref("places.semanticHistory.featureGate", false);
      pref("browser.urlbar.quicksuggest.enabled", false);
      pref("network.http.max-connections", 64);
      pref("network.http.max-persistent-connections-per-server", 4);
      pref("image.mem.decode_bytes_at_a_time", 65536);
      pref("places.history.expiration.max_pages", 20000);
      ```

`places.semanticHistory.featureGate` is the local embedding model behind urlbar
history search — same family as `browser.ml.enable`, separately gated. The
connection limits stop Firefox opening sockets it cannot feed on this radio.
Larger decode chunks cut per-chunk overhead in the software image decoder.
Capping places at 20k pages keeps `places.sqlite` small, which is the file the SD
card handles worst.

### Tier 2 — small, real losses

- [ ] Background timer throttling, captive portal probes and reader parsing:
      ```
      pref("dom.min_background_timeout_value", 10000);
      pref("network.captive-portal-service.enabled", false);
      pref("network.connectivity-service.enabled", false);
      pref("reader.parse-on-load.enabled", false);
      ```

Background timers at 10s stop background tabs waking four slow cores, and break
web apps that poll while backgrounded. Captive portal detection off removes
periodic probes — a genuine loss on a phone that joins public WiFi, where you get
a silent failure instead of a sign-in prompt. Reader parse-on-load off stops
every page going through the readability parser, at the cost of the reader-mode
button appearing.

### Tier 3 — visible feature removal, meaningful savings

- [ ] Web push and notifications, picture-in-picture, the media helper
      processes, and HTTP/3:
      ```
      pref("dom.push.enabled", false);
      pref("dom.webnotifications.enabled", false);
      pref("beacon.enabled", false);
      pref("media.videocontrols.picture-in-picture.enabled", false);
      pref("media.rdd-process.enabled", false);
      pref("media.utility-process.enabled", false);
      pref("network.http.http3.enable", false);
      ```

`media.rdd-process.enabled` and `media.utility-process.enabled` fold media
decoding back into existing processes — roughly 30–50MB of per-process overhead
recovered, against the sandbox isolation around media parsing, historically a
rich source of exploits. Defensible at 2972MB, but it is a real trade.

`network.http.http3.enable` is the one to measure rather than assume. QUIC is
userspace with no kernel offload, so HTTP/2 over TCP is sometimes cheaper on a
CPU-bound device — but it is workload-dependent and untested here.

### Tier 4 — losing capabilities

- [ ] DRM, WebRTC, Safe Browsing, OCSP and service workers:
      ```
      pref("media.eme.enabled", false);
      pref("media.gmp-provider.enabled", false);
      pref("media.peerconnection.enabled", false);
      pref("browser.safebrowsing.malware.enabled", false);
      pref("browser.safebrowsing.phishing.enabled", false);
      pref("browser.safebrowsing.downloads.enabled", false);
      pref("browser.safebrowsing.downloads.remote.enabled", false);
      pref("browser.safebrowsing.blockedURIs.enabled", false);
      pref("security.OCSP.enabled", 0);
      pref("dom.serviceWorkers.enabled", false);
      ```
- [ ] **`webrtcSupport = false`** on the unwrapped package, paired with
      `media.peerconnection.enabled`. Strips a large amount of code out of
      `libxul.so` and shortens every cold start. No browser video calls after
      that.

EME off kills Netflix, Spotify and anything else using DRM, and stops the
Widevine CDM being downloaded into the profile at all. Safe Browsing off is the
largest data and storage saving on this list — the v4 lists update on a timer and
occupy a sizeable part of the profile directory, on the card, permanently; you
lose phishing and malware warnings. OCSP off removes a blocking round-trip from
TLS handshakes on a high-latency link, with CRLite covering some revocation but
not all. Service workers off breaks offline-capable sites and PWAs; safe from our
side, since [`weblaunch.nix`](../nix/5-phone/3-apps/core/weblaunch.nix) does not
run through Firefox.

### Tier 5 — a different browser, effectively

- [ ] Web fonts, images and JavaScript:
      ```
      pref("gfx.downloadable_fonts.enabled", false);
      pref("permissions.default.image", 2);
      pref("javascript.enabled", false);
      ```

Web fonts off saves the download and the rasterisation and breaks every site
using an icon font — replacement boxes in navigation bars. Images off is
transformative for data and paint cost and makes most of the web unusable. JS off
is the end of the line.

### Not recommended

Lowering `security.sandbox.content.level`. It gives back very little and costs
the process isolation that the reduced `dom.ipc.processCount` and disabled
Fission already lean on.
