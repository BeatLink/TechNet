# Waydroid ###########################################################################################################################################
#
# Android in an LXC container on the host kernel, rendering into the phosh session. The system and vendor images are not packaged: they are fetched by
# `sudo waydroid init` on first run, into the persisted /var/lib/waydroid, and the session then starts with `waydroid session start`.
#

{ pkgs, lib, ... }:
let
    waydroidPackage = pkgs.waydroid-nftables;

    # Android sleeps on its own timeout and asks the host to suspend it, which freezes the container -- worth keeping, because a frozen container
    # costs nothing at all. What upstream never supplies is the other half: maybeLaunchLater unfreezes the cgroup but nothing wakes Android's
    # display, so no surface is ever mapped and the window looks dead. Verified here: SLEEP then WAKEUP moves mWakefulness both ways, and an
    # unfreeze followed by a wake brings a genuinely FROZEN container back to RUNNING and Awake.
    #
    # The binary is wrapped rather than the launchers because waydroid writes a .desktop per installed app as it installs them, all of them calling
    # `waydroid app launch`; there is no one file to patch. It goes on virtualisation.waydroid.package so the wrapper IS the waydroid on PATH --
    # adding a second copy to the user profile would leave which one a launcher resolves up to PATH order.
    wakeBeforeShowing = pkgs.writeShellScript "waydroid-wake-before-showing" ''
        # Only the subcommands that put a window on screen. `shell` must never match: the wake below goes through it and would recurse.
        case "''${1-}" in
            show-full-ui | app | first-launch) ;;
            *) exit 0 ;;
        esac

        # Both are best-effort: a container that is already thawed and awake answers these harmlessly, and a broken one must not block the launch.
        ${waydroidPackage}/bin/waydroid container unfreeze >/dev/null 2>&1 || true
        /run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
    '';

    waydroidWake = pkgs.symlinkJoin {
        name = "waydroid-wake";
        paths = [ waydroidPackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/waydroid --run '${wakeBeforeShowing} "$@"'
        '';
    };

    # lswt binds the newer ext-foreign-toplevel-list-v1 unconditionally where both exist, and that protocol carries no state -- no activated flag, so no
    # focus events at all. The wlr protocol is the one that answers "which window is focused", so prefer it. Same patch focus-boost.nix carries.
    lswt = pkgs.lswt.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace lswt.c \
                --replace-fail \
                    "used_protocol = EXT_FOREIGN_TOPLEVEL;" \
                    "used_protocol = (zwlr_toplevel_manager == NULL) ? EXT_FOREIGN_TOPLEVEL : ZWLR_FOREIGN_TOPLEVEL;"
        '';
    });

    # While a Waydroid window is focused this owns rotation outright: it takes phosh's rotation lock, forces the panel to portrait through the same
    # DisplayConfig DBus interface phosh-mobile-settings uses, and drives Android's user_rotation from the accelerometer; on focus loss it puts the
    # user's own lock preference and transform back. Locking alone is not enough -- phosh's lock freezes whatever transform is current, so a session
    # docked in landscape would freeze landscape under the portrait-shaped Waydroid surface and every app would render sideways.
    rotationBridge =
        pkgs.writers.writePython3Bin "waydroid-rotation"
            {
                libraries = [ pkgs.python3Packages.pygobject3 ];
                flakeIgnore = [ "E501" ];
            }
            ''
                import os
                import re
                import signal
                import subprocess
                import sys
                import threading
                import gi
                gi.require_version("Gio", "2.0")
                from gi.repository import Gio, GLib  # noqa: E402

                LOCK_KEY = "/org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock"
                # Android's constants count quarter turns of the device: ROTATION_90 is the device turned counter-clockwise, which puts the right edge up.
                ORIENTATION = {"normal": "0", "right-up": "1", "bottom-up": "2", "left-up": "3"}
                PREFIX = "waydroid"
                # The accelerometer flaps between two readings when the phone is near flat, and every flip costs Android a re-layout, so a reading has to hold.
                SETTLE = 1.2
                PREF_FILE = os.environ.get("XDG_RUNTIME_DIR", "/tmp") + "/waydroid-rotation.pref"

                DCONF = "${pkgs.dconf}/bin/dconf"
                WAYDROID = ["/run/wrappers/bin/sudo", "-n", "${waydroidPackage}/bin/waydroid", "shell"]

                RE_APPID = re.compile(r"^toplevel (\d+): set app-id: '[^']*' -> '([^']*)'")
                RE_ACTIVE = re.compile(r"^\[toplevel (\d+): set activated: ([01])\]")
                RE_GONE = re.compile(r"^toplevel (\d+): destroyed")

                state = {
                    "focused": False,
                    "app_id": None,
                    "pref": "false",
                    "lock_now": "false",
                    "expect": [],
                    "saved": None,
                    "orientation": None,
                    "applied": None,
                    "settle": 0,
                    "shell": None,
                    "stopping": False,
                }

                loop = GLib.MainLoop()

                session = Gio.bus_get_sync(Gio.BusType.SESSION)
                display_config = Gio.DBusProxy.new_sync(
                    session, Gio.DBusProxyFlags.NONE, None,
                    "org.gnome.Mutter.DisplayConfig", "/org/gnome/Mutter/DisplayConfig",
                    "org.gnome.Mutter.DisplayConfig", None,
                )


                def monitor_state():
                    serial, monitors, logical, _props = display_config.call_sync("GetCurrentState", None, Gio.DBusCallFlags.NONE, -1, None).unpack()
                    connector = monitors[0][0][0]
                    mode = next(m[0] for m in monitors[0][1] if m[6].get("is-current"))
                    return serial, connector, mode, logical[0][2], logical[0][3]


                def set_transform(transform):
                    serial, connector, mode, scale, current = monitor_state()
                    if current == transform:
                        return
                    # Method 2 (persistent) is the only one phosh acts on: temporary configs are parsed and then dropped without being applied.
                    args = GLib.Variant("(uua(iiduba(ssa{sv}))a{sv})", (serial, 2, [(0, 0, scale, transform, True, [(connector, mode, {})])], {}))
                    display_config.call_sync("ApplyMonitorsConfig", args, Gio.DBusCallFlags.NONE, -1, None)


                def dconf_write(value):
                    # dconf emits no event for an unchanged write, which would strand the expectation entry and eat a later real one.
                    if state["lock_now"] == value:
                        return
                    state["lock_now"] = value
                    state["expect"].append(value)
                    subprocess.run([DCONF, "write", LOCK_KEY, value], capture_output=True, timeout=10)


                def save_pref(value):
                    state["pref"] = value
                    with open(PREF_FILE, "w") as f:
                        f.write(value)


                def android(rotation):
                    for _ in range(2):
                        shell = state["shell"]
                        if shell is None or shell.poll() is not None:
                            state["shell"] = shell = subprocess.Popen(WAYDROID, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, text=True)
                        try:
                            shell.stdin.write("settings put system user_rotation " + rotation + "\n")
                            shell.stdin.flush()
                            return
                        except OSError:
                            state["shell"] = None


                def apply_rotation():
                    rotation = ORIENTATION.get(state["orientation"] or "")
                    if rotation is None or not state["focused"] or rotation == state["applied"]:
                        return
                    android(rotation)
                    state["applied"] = rotation
                    print("rotation " + rotation + " (" + state["orientation"] + ")", flush=True)


                def cancel_settle():
                    if state["settle"]:
                        GLib.source_remove(state["settle"])
                        state["settle"] = 0


                def on_orientation(orientation):
                    state["orientation"] = orientation

                    def fire():
                        state["settle"] = 0
                        apply_rotation()
                        return False

                    cancel_settle()
                    state["settle"] = GLib.timeout_add(int(SETTLE * 1000), fire)


                def fullscreen(app_id, on):
                    # Maximized keeps phosh's bars and scale-to-fit letterboxes the fixed-aspect surface; only fullscreen makes it cover the panel exactly.
                    if not app_id:
                        return
                    subprocess.run(["${pkgs.wlrctl}/bin/wlrctl", "toplevel", "fullscreen" if on else "unfullscreen", "app_id:" + app_id], capture_output=True, timeout=10)


                def on_focus(target):
                    if bool(target) == state["focused"] and target == state["app_id"]:
                        return
                    if target and state["focused"]:
                        fullscreen(state["app_id"], False)
                        fullscreen(target, True)
                        state["app_id"] = target
                        return
                    state["focused"] = bool(target)
                    print(("took" if target else "released") + " rotation ownership", flush=True)
                    if target:
                        state["app_id"] = target
                        dconf_write("true")
                        fullscreen(target, True)
                        try:
                            state["saved"] = monitor_state()[4]
                            set_transform(0)
                        except GLib.Error as err:
                            print("transform: " + err.message, flush=True)
                        state["applied"] = None
                        apply_rotation()
                    else:
                        cancel_settle()
                        fullscreen(state["app_id"], False)
                        state["app_id"] = None
                        android("0")
                        state["applied"] = None
                        if state["pref"] == "true":
                            if state["saved"] is not None:
                                try:
                                    set_transform(state["saved"])
                                except GLib.Error as err:
                                    print("transform: " + err.message, flush=True)
                        else:
                            # Releasing the lock is enough for the transform: phosh re-runs its own orientation match on unlock.
                            dconf_write("false")
                        state["saved"] = None


                def on_lock_changed(value):
                    state["lock_now"] = value
                    if state["expect"] and state["expect"][0] == value:
                        state["expect"].pop(0)
                        return
                    save_pref(value)
                    if state["focused"] and value != "true":
                        dconf_write("true")


                system = Gio.bus_get_sync(Gio.BusType.SYSTEM)
                sensor = Gio.DBusProxy.new_sync(
                    system, Gio.DBusProxyFlags.NONE, None,
                    "net.hadess.SensorProxy", "/net/hadess/SensorProxy",
                    "net.hadess.SensorProxy", None,
                )


                def claim(*_args):
                    # The claim dies with the proxy's connection, so it has to be retaken every time the name gains an owner.
                    if sensor.get_name_owner() is None:
                        return
                    try:
                        sensor.call_sync("ClaimAccelerometer", None, Gio.DBusCallFlags.NONE, -1, None)
                    except GLib.Error as err:
                        print("claim: " + err.message, flush=True)
                        return
                    cached = sensor.get_cached_property("AccelerometerOrientation")
                    if cached is not None:
                        on_orientation(cached.get_string())


                sensor.connect("notify::g-name-owner", claim)
                sensor.connect(
                    "g-properties-changed",
                    lambda _p, changed, _i: (
                        on_orientation(changed["AccelerometerOrientation"])
                        if "AccelerometerOrientation" in changed.keys() else None
                    ),
                )


                def watch_toplevels():
                    app_ids = {}
                    active = set()
                    proc = subprocess.Popen(
                        ["${pkgs.coreutils}/bin/stdbuf", "-oL", "${lswt}/bin/lswt", "-w", "--debug"],
                        stdout=subprocess.PIPE, text=True,
                    )
                    for line in proc.stdout:
                        m = RE_APPID.match(line)
                        if m:
                            app_ids[m.group(1)] = m.group(2)
                            continue
                        m = RE_ACTIVE.match(line)
                        if m:
                            if m.group(2) == "1":
                                active.add(m.group(1))
                                app_id = app_ids.get(m.group(1)) or ""
                                GLib.idle_add(on_focus, app_id if app_id.lower().startswith(PREFIX) else None)
                            else:
                                active.discard(m.group(1))
                                if not active:
                                    GLib.idle_add(on_focus, None)
                            continue
                        m = RE_GONE.match(line)
                        if m:
                            app_ids.pop(m.group(1), None)
                            active.discard(m.group(1))
                            if not active:
                                GLib.idle_add(on_focus, None)
                    # lswt dying means focus is invisible, so leave and let systemd restart the whole bridge.
                    GLib.idle_add(loop.quit)


                def watch_lock():
                    proc = subprocess.Popen([DCONF, "watch", LOCK_KEY], stdout=subprocess.PIPE, text=True)
                    for line in proc.stdout:
                        value = line.strip()
                        if value in ("true", "false"):
                            GLib.idle_add(on_lock_changed, value)


                def shutdown():
                    state["stopping"] = True
                    on_focus(None)
                    loop.quit()
                    return False


                out = subprocess.run([DCONF, "read", LOCK_KEY], capture_output=True, text=True, timeout=10)
                state["lock_now"] = "true" if out.stdout.strip() == "true" else "false"
                save_pref(state["lock_now"])

                GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, shutdown)
                claim()

                for target in (watch_toplevels, watch_lock):
                    thread = threading.Thread(target=target, daemon=True)
                    thread.start()

                loop.run()
                sys.exit(0 if state["stopping"] else 1)
            '';

    # If the bridge dies mid-focus the lock would stay held forever, so put back whatever preference it last recorded.
    restoreLock = pkgs.writeShellScript "waydroid-rotation-restore" ''
        ${pkgs.dconf}/bin/dconf write /org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock "$(${pkgs.coreutils}/bin/cat "$XDG_RUNTIME_DIR/waydroid-rotation.pref" 2>/dev/null || echo false)"
    '';

    # The container unit staying active is not proof Android is up: the unit is the manager, and the LXC container inside it can die on its own,
    # leaving `Session: RUNNING` beside `Container: STOPPED` with nothing to notice. Only the session can ask for the container back, so that is what gets restarted.
    #
    # Bounded to three consecutive attempts, reset the moment the container is seen RUNNING, so a container that can never start cannot loop on battery.
    containerWatch = pkgs.writeShellScript "waydroid-container-watch" ''
        status=$(/run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid status 2>/dev/null)
        session=$(printf '%s\n' "$status" | ${pkgs.gawk}/bin/awk -F'\t' '/^Session:/ { print $2 }')
        container=$(printf '%s\n' "$status" | ${pkgs.gawk}/bin/awk -F'\t' '/^Container:/ { print $2 }')
        attempts="$XDG_RUNTIME_DIR/waydroid-container-watch"

        [ "$container" = "RUNNING" ] && { echo 0 > "$attempts"; exit 0; }
        [ "$session" = "RUNNING" ] || exit 0

        tries=$(cat "$attempts" 2>/dev/null || echo 0)
        case "$tries" in *[!0-9]* | "") tries=0 ;; esac
        [ "$tries" -ge 3 ] && exit 0
        echo $((tries + 1)) > "$attempts"
        ${pkgs.systemd}/bin/systemctl --user restart --no-block waydroid-session
    '';

    # Nothing Android-side answers until the container finishes booting, which is minutes from cold on this hardware.
    waitBooted = ''
        booted=
        # 36 x 5s must stay well under home-manager's 5min unit start timeout, or a container that never boots fails the whole deploy.
        for _ in $(seq 1 36); do
            booted=$(/run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- getprop sys.boot_completed 2>/dev/null | tr -dc '0-9')
            [ "$booted" = "1" ] && break
            sleep 5
        done
        [ "$booted" = "1" ] || exit 0
    '';

    # Android's own auto-rotation is turned off because it has no sensor to rotate by: waydroid-rotation drives user_rotation instead, and the two
    # would otherwise each apply a quarter turn. force_resizable_activities is what makes apps reflow into whatever window they are given.
    #
    # Android state lives in the container's userdata, so it survives reboots but not a re-init; reapplying it every session start is what makes it declarative.
    # Measured on this phone before any of this: the container held 1794MB and 158% of a core, of which Play Store's four processes were ~718MB and
    # GMS' three ~674MB -- roughly 80% between them, against 954MB free on a 2968MB device. Only six of 179 packages were disabled.
    #
    # Everything here is disable-user where the package allows it, so `pm enable` puts any of it back without a re-init. Google's own store and
    # framework stay: com.android.vending, gms, gsf, webview and packageinstaller are what apps are installed and run through.
    disabledPackages = [
        # Superseded by the phone's own applications
        "com.google.android.apps.messaging"
        "com.google.android.contacts"
        "com.google.android.dialer"
        "com.google.android.syncadapters.calendar"
        "com.google.android.apps.googlecamera.fishfood"
        "com.android.cameraextensions"
        "org.lineageos.recorder"
        "com.android.gallery3d"
        "com.android.deskclock"
        "com.android.calculator2"

        # No calendar application is installed, so the provider and its sync adapter have nothing to serve
        "com.android.providers.calendar"

        # Assistant and search: the largest single consumer after the store and the framework
        "com.google.android.googlequicksearchbox"
        "com.google.android.as"
        "com.google.android.as.oss"

        # Nothing in a container has a modem, a printer, a car or a second screen to reach
        "com.google.android.ims"
        "com.android.emergency"
        "com.android.simappdialog"
        "com.android.stk"
        "com.android.cellbroadcastreceiver"
        "com.android.bips"
        "com.android.printspooler"
        "com.google.android.printservice.recommendation"
        "com.google.android.projection.gearhead"
        "com.android.companiondevicemanager"

        # Ran once, or never will
        "com.google.android.setupwizard"
        "com.google.android.onetimeinitializer"
        "com.google.android.partnersetup"
        "com.google.android.apps.restore"
        "com.android.managedprovisioning"
        "com.android.dynsystem"
        "com.android.cts.ctsshim"
        "com.android.cts.priv.ctsshim"

        # Background telemetry, supervision and verification, none of which this device is asking for
        "com.google.android.apps.turbo"
        "com.google.android.feedback"
        "com.google.android.configupdater"
        "com.google.android.verifier"
        "com.google.android.safetycore"
        "com.google.android.gms.location.history"
        "com.google.android.gms.supervision"

        # Screensavers, wallpapers and an easter egg, on a screen that is a window on another host's compositor
        "com.android.dreams.basic"
        "com.android.dreams.phototable"
        "com.android.wallpaper"
        "com.android.wallpaper.livepicker"
        "com.android.wallpaperbackup"
        "com.android.bookmarkprovider"
        "com.android.traceur"
        "com.android.egg"
    ];

    androidConfig = pkgs.writeShellScript "waydroid-android-config" ''
        ${waitBooted}

        /run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- sh -c '
            pm disable com.google.android.gms/.chimera.GmsIntentOperationService
            for package in ${lib.concatStringsSep " " disabledPackages}; do
                # disable-user is reversible and needs no system uid; the fallback catches the handful that are not user-disableable
                pm disable-user --user 0 "$package" >/dev/null 2>&1 || pm disable "$package" >/dev/null 2>&1 || true
            done

            # Android 13 freezes cached processes rather than leaving them schedulable, which is the difference between idle and merely quiet
            settings put global cached_apps_freezer enabled
            # low_ram already trims the cache; this pins it rather than leaving it to a heuristic sized for a phone with more memory
            settings put global activity_manager_constants max_cached_processes=4
            settings put secure backup_enabled 0
            # Long enough not to sleep out from under a session; it still sleeps and freezes eventually, and the wrapper wakes it when it has
            settings put system screen_off_timeout 1800000
            # The three background processes of the store came to ~436MB on their own, and nothing here installs apps unattended
            cmd appops set com.android.vending RUN_ANY_IN_BACKGROUND deny
            cmd appops set com.android.vending RUN_IN_BACKGROUND deny
            wm size reset
            wm density 270 # 720px at 270 is the same 426dp of layout width that 1440px at 540 gave, so only the pixel count drops
            settings put global hide_error_dialogs 1
            settings put global force_resizable_activities 1
            settings put global enable_freeform_support 0
            settings put system accelerometer_rotation 0
            settings put global window_animation_scale 0
            settings put global transition_animation_scale 0
            settings put global animator_duration_scale 0
        ' > /dev/null
    '';

    # Pinned rather than taken from f-droid.org/F-Droid.apk so the installed version is whatever this generation says it is; F-Droid updates itself
    # afterwards, and the higher version code then makes the install step below a no-op.
    fdroidApk = pkgs.fetchurl {
        url = "https://f-droid.org/repo/org.fdroid.fdroid_2000040.apk";
        hash = "sha256-zUkrotWkJa2AqiL0sT2YFbKtSH6bK232tnwxuVexnys=";
    };

    # `app install` is the user-side path: it copies the APK into the session's own data directory and hands it to Waydroid's platform service, which
    # installs silently as system. The appop is what a sideloaded F-Droid otherwise has to be granted by hand before it can install anything itself.
    fdroidInstall = pkgs.writeShellScript "waydroid-fdroid" ''
        ${waitBooted}

        installed() {
            /run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- pm list packages org.fdroid.fdroid 2>/dev/null | tr -d '\r' | ${pkgs.gnugrep}/bin/grep -qx 'package:org.fdroid.fdroid'
        }

        if ! installed; then
            ${waydroidPackage}/bin/waydroid app install ${fdroidApk} || exit 1
            for _ in $(seq 1 30); do
                installed && break
                sleep 2
            done
            installed || exit 1
        fi

        /run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- appops set org.fdroid.fdroid REQUEST_INSTALL_PACKAGES allow > /dev/null
    '';

    # Android decides a device is a tablet when it finds no telephony feature, and WhatsApp then offers only companion QR pairing.
    telephonyFeature = pkgs.writeText "android.hardware.telephony.xml" ''
        <?xml version="1.0" encoding="utf-8"?>
        <permissions>
            <feature name="android.hardware.telephony" />
            <feature name="android.hardware.telephony.gsm" />
        </permissions>
    '';
in
{
    # Waydroid brings up waydroid0 at 192.168.240.1/24 with its own dnsmasq, and the firewall already trusts the interface, but nothing masquerades
    # the subnet -- so Android's packets reach the host and die there. Verified on 2026-09-09: gateway and LAN reachable, 1.1.1.1 and DNS both failing
    # until a masquerade existed, all four passing after.
    #
    # externalInterface stays null on purpose. The module only emits `-o <iface>` when it is set, so leaving it out masquerades onto whichever
    # interface the route picks -- wifi, WireGuard or mobile data. Naming one would break Android's networking on the other two.
    networking.nat = {
        enable = true;
        internalInterfaces = [ "waydroid0" ];
    };

    virtualisation.waydroid.enable = true;

    # nixpkgs wants the container at multi-user.target but gives it no restart policy at all, so anything that stops it leaves Android gone until
    # something starts it by hand -- which is what a stopped container looked like here. The session unit already restarts itself this way.
    #
    # on-failure rather than always, deliberately: `waydroid container stop` and the stop half of a restart both exit cleanly, and always would
    # fight them, turning a deliberate stop into a restart loop.
    systemd.services.waydroid-container.serviceConfig = {
        Restart = "on-failure";
        RestartSec = 10;
    };
    # waydroid-nftables speaks to nftables directly rather than through the legacy iptables tables; the wrapper adds the wake described above
    virtualisation.waydroid.package = waydroidWake;

    # Copied rather than symlinked because a store path does not resolve inside the container, and C only creates, so editing this needs the old file deleted.
    systemd.tmpfiles.settings."waydroid-overlay" = {
        "/var/lib/waydroid/overlay/vendor/etc/permissions".d = {
            user = "root";
            group = "root";
            mode = "0755";
        };
        "/var/lib/waydroid/overlay/vendor/etc/permissions/android.hardware.telephony.xml".C = {
            user = "root";
            group = "root";
            mode = "0644";
            argument = "${telephonyFeature}";
        };
    };

    # ro.opengles.version is hardcoded to 196610 (GLES 3.2) because Waydroid probes for it with Android's own getprop, which no Linux host has; lima
    # only offers 2.0. ro.config.low_ram puts Android in its small-device profile, which matters on 3 GB shared with phosh.
    systemd.services.waydroid-props = {
        description = "Pin the Waydroid properties that its own defaults get wrong on this hardware";
        wantedBy = [ "multi-user.target" ];
        before = [ "waydroid-container.service" ];
        after = [ "var-lib-waydroid.mount" ];
        path = [
            pkgs.gnugrep
            pkgs.gnused
        ];
        unitConfig.ConditionPathExists = "/var/lib/waydroid/waydroid.cfg";
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        # waydroid.cfg is the durable copy that survives an upgrade, and waydroid_base.prop is the one the container actually reads.
        script = ''
            cfg=/var/lib/waydroid/waydroid.cfg
            prop=/var/lib/waydroid/waydroid_base.prop

            grep -q '^\[properties\]' "$cfg" || printf '\n[properties]\n' >> "$cfg"

            # Logical pixels, multiplied by the 1.5 fractional scale to size the buffer. 960x1920 made the buffer 1440x2880 for a 720x1440 panel, so the
            # Mali-400 drew 4.1MP for a 1.0MP screen and every launcher frame missed vblank on "slow issue draw commands"; halving it took the median
            # frame from 200ms to 23ms. Native apps never had this because they size from wl_output -- only Waydroid sizes itself from a prop.
            #
            # This is the whole panel rather than the usable area because phoc's scale-to-fit is off in display.nix. With it on, hwcomposer's
            # xdg_toplevel configure handler took the shrunken size as its viewport destination while the buffer kept the size set here, so the
            # difference showed as a permanent letterbox.
            #
            # Multi-window stays off because those windows never resize after session start either, and one app filling the screen is what this hardware wants.
            for pair in ro.opengles.version=131072 ro.config.low_ram=true persist.waydroid.width=480 persist.waydroid.height=960 persist.waydroid.multi_windows=false; do
                key=''${pair%%=*}
                value=''${pair#*=}

                if grep -q "^$key" "$cfg"; then
                    sed -i "s|^$key.*|$key = $value|" "$cfg"
                else
                    sed -i "/^\[properties\]/a $key = $value" "$cfg"
                fi

                if [ -f "$prop" ]; then
                    if grep -q "^$key" "$prop"; then
                        sed -i "s|^$key=.*|$key=$value|" "$prop"
                    else
                        echo "$key=$value" >> "$prop"
                    fi
                fi
            done
        '';
    };

    # The props unit is gated on a file that only `waydroid init` creates, so on a fresh install it is skipped at boot and Android's first start reads
    # the defaults it exists to override. This fires the moment init writes the config, before any session can start against it.
    systemd.paths.waydroid-props = {
        description = "Run waydroid-props once waydroid init has written its config";
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
            PathExists = "/var/lib/waydroid/waydroid.cfg"; # PathExists, not PathChanged: waydroid rewrites the file itself and a change trigger would loop
            Unit = "waydroid-props.service";
        };
    };

    environment.persistence."/Storage/System/Waydroid".directories = [
        {
            directory = "/var/lib/waydroid";
            user = "root";
            group = "root";
            mode = "u=rwx,g=rx,o=rx";
        }
    ];

    home-manager.users.beatlink = {
        home.persistence."/Storage/Apps/System/Waydroid" = {
            directories = [
                ".local/share/waydroid"
            ];
        };

        systemd.user.services = {
            # The session is the user-side half of Waydroid: the container runs as a system service, but the Wayland client belongs to the graphical session.
            waydroid-session = {
                Unit = {
                    Description = "Waydroid session";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };
                Service = {
                    # `session start` blocks only when it owns the session; against an existing one it prints "already running" and exits, which
                    # systemd reads as the service finishing and answers with ExecStop, killing the session. Clearing it first keeps that from happening.
                    ExecStartPre = "-${waydroidPackage}/bin/waydroid session stop";
                    ExecStart = "${waydroidPackage}/bin/waydroid session start";
                    ExecStop = "${waydroidPackage}/bin/waydroid session stop";
                    Restart = "on-failure";
                    RestartSec = 15;
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };

            waydroid-container-watch = {
                Unit = {
                    Description = "Restart the Waydroid session if its container has died underneath it";
                    After = [ "waydroid-session.service" ];
                };
                Service = {
                    Type = "oneshot";
                    ExecStart = "${containerWatch}";
                };
            };

            waydroid-rotation = {
                Unit = {
                    Description = "Own rotation while a Waydroid window is focused";
                    PartOf = [ "waydroid-session.service" ];
                    After = [ "waydroid-android-config.service" ];
                };
                Service = {
                    ExecStart = "${rotationBridge}/bin/waydroid-rotation";
                    ExecStopPost = "${restoreLock}";
                    Restart = "on-failure";
                    RestartSec = 15;
                };
                Install.WantedBy = [ "waydroid-session.service" ];
            };

            waydroid-fdroid = {
                Unit = {
                    Description = "Install F-Droid into the Waydroid container";
                    PartOf = [ "waydroid-session.service" ];
                    After = [ "waydroid-android-config.service" ];
                };
                Service = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    TimeoutStartSec = 240;
                    ExecStart = "${fdroidInstall}";
                };
                Install.WantedBy = [ "waydroid-session.service" ];
            };

            waydroid-android-config = {
                Unit = {
                    Description = "Reapply the Android-side settings that Waydroid keeps in userdata";
                    PartOf = [ "waydroid-session.service" ];
                    After = [ "waydroid-session.service" ];
                };
                Service = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    TimeoutStartSec = 240;
                    ExecStart = "${androidConfig}";
                };
                Install.WantedBy = [ "waydroid-session.service" ];
            };
        };

        # Wanted by timers.target rather than the session, so a session that has died still gets checked; the script itself no-ops unless the session is up.
        systemd.user.timers.waydroid-container-watch = {
            Unit.Description = "Check that Waydroid's container is still alive";
            Timer = {
                OnStartupSec = "2min";
                OnUnitInactiveSec = "1min";
            };
            Install.WantedBy = [ "timers.target" ];
        };
    };
}
