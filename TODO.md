# TODO

Outstanding work, most blocking first. Background for the Thor items is in [docs/thor.md](docs/thor.md).

## In flight

Built and waiting to deploy, most of it unverified on hardware.

* Deploy Ragnarok: SMR queue depths and Syncthing CPU quota
* Syncthing GUI password and reverse proxy, all hosts

## Ragnarok

* Setup ZFS Optimizations
* Setup Syncthing Optimizations
* autotrim is a no-op behind the SATA-to-USB bridge
* Data disk is SMR, so write stalls have a floor

## Odin

* Backups only cover /Storage/System, which is 7.5K
* aarch64 now builds here under binfmt, not on Ragnarok

## Thor

* Optimization ideas

  * CPU Optimization
  * * Foreground booster
  * IO Optimization
  * prewarm dynamic app recording
    * While an app is running, record the pages and files it accessed and save so that next time prewarming is done, those records are added
  * Every app's persistence is on the SD card. /Storage is data-pool-Thor on
    mmcblk0 (SD); only /, /nix, /home and /persistent are on the eMMC. Measured
    2.4x slower per file than eMMC -- 3028us vs 1288us -- and reading Home
    Assistant's 5500-file profile cold takes 16.7s. Moving /Storage/Apps to the
    eMMC is worth ~2.4x but needs a size audit first: it is 2.9G against 28.5G
    of eMMC, and /Storage/Apps/System alone is 1.9G.
  * primarycache=metadata on data-pool-Thor/storage denies the ARC 2.9G of hot
    app state -- every browser profile and cache. The policy was written for
    bulk media, which app profiles are the opposite of. The same experiment
    that settled it for /nix (32-arc-policy.nix) would settle it here; the
    finding there was that the ARC is elastic and manages the tension itself.
  * /Storage/Apps holds 387M of dead data: Core/Firefox is 311M and
    Core/Chromium 76M, both for apps that were removed. Nothing reads them.
  * Waydroid is 1.9G of the 2.9G under /Storage/Apps, so any plan to move app
    persistence to the eMMC is really a question about Waydroid first.
  * Preload profiles go stale on a nixpkgs bump, since the recorded paths are
    exact store paths. app-preload warns when over half are gone but nothing
    re-records. Automate if it bites.
  * Consider consolidating WebLaunch onto Epiphany's engine. WebLaunch is
    WebKit under GTK3 and costs ~95 MiB of the locked set that Epiphany's
    abi=6.0 engine would make free. Blocked on re-measuring the compositing
    finding in weblaunch.nix -- both engines now hold /dev/dri/renderD128 under
    mesa 26.1.5, so "GTK4 is refused by lima" may no longer hold, but device
    access is not proof of hardware compositing.
  * Rewrite PinePhoneCharge in Vala, as Prewarm now is. Measured on the phone,
    `chargectl --help` costs 839-1810ms against 21ms for a native binary --
    that is interpreter startup and the PyGObject import, paid on every
    invocation, and the GTK4/libadwaita GUI pays considerably more than
    --help does. Three parts to move: the CLI, the polling daemon, and the
    GUI. Vala suits the GUI especially, being GObject natively.
  * Retire nix/5-phone/1-system/31-app-preload in favour of the Prewarm flake
    (/Storage/Files/Projects/Coding/Prewarm), once the warm-pass timing is
    confirmed on hardware. The module there is services.prewarm.
  * The old preloader recorded read()-opened store files via strace as well as
    mapped ones; Prewarm records only mappings, from pagemap. Most of that set
    was shared libraries, which are mapped, so recording with minSize=0 should
    cover it -- but icons, locales and gsettings schemas are read(), not
    mapped, and would need warmDirs or a records-files mode to stay covered.
* [www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/?__goaway_challenge=meta-refresh&amp;__goaway_id=df93c11d9ee5b312d692e413745c8585&amp;__goaway_referer=https%3A%2F%2Fduckduckgo.com%2F](https://www.freedesktop.org/wiki/Specifications/desktop-bookmark-spec/?__goaway_challenge=meta-refresh&__goaway_id=df93c11d9ee5b312d692e413745c8585&__goaway_referer=https%3A%2F%2Fduckduckgo.com%2F)
* 
* Setup Waydroid
* Figure how to run android apps on pinephone
* Fix spellcheck dictionary
* Shut down 5s after a failed login, via PAM so serial, ssh and screen all count
* Duress password via pam_duress
* Update login password to digits, Thor only
* phoc segfaults on touch-up in wlr_surface_get_root_surface, takes every app with it
* Fix rotation on lockscreen (May be upstream)
* Setup Front and Rear Camera
* Validate NixTool Local install procedure and write procedure for using it to update towboot in emmc mode
* Fix Ragnarok AArch64 remote building
* Setup Build caching for zfs kernel on thor
* Fix all partlabel collisions between odin and thor
* Research phosh plugins
* Add wipefs prior to installation for disks
* Let the initrd join more than one WiFi network, it cannot unlock away from home
* WireGuard in initrd, but only after roaming, and not via the shared module
* Review and install apps

  * Login and sync firefox
  * Setup Trilium
  * Syncthing
  * Setup Matrix
  * Setup Discord
  * Setup Phone
  * Setup SMS

## Troubleshooting

Kept so the same ground is not re-covered.

| Symptom                         | Cause                                        | Solution                               |
| ------------------------------- | -------------------------------------------- | -------------------------------------- |
| Serial garbage at every baud    | Two readers on one port, not a baud mismatch | Use multiplexing with multiple readers |
| `nixos-anywhere` kexec failed | postmarketOS kernel has no`kexec_load`     | Use NixTool's local install mode       |
