# Waydroid ##########################################################################################################################################
#
# Android in an LXC container on the host kernel, rendering into the phosh session. The system and vendor images are not packaged: they are fetched by
# `sudo waydroid init` on first run, into the persisted /var/lib/waydroid, and the session then starts with `waydroid session start`.
#

{ pkgs, ... }:
let
    waydroidPackage = pkgs.waydroid-nftables;

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
    rotationBridge = pkgs.writers.writePython3Bin "waydroid-rotation" {
        libraries = [ pkgs.python3Packages.pygobject3 ];
        flakeIgnore = [ "E501" ];
    } ''
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

    # Android's own auto-rotation is turned off because it has no sensor to rotate by: waydroid-rotation drives user_rotation instead, and the two
    # would otherwise each apply a quarter turn. force_resizable_activities is what makes apps reflow into whatever window they are given.
    #
    # Android state lives in the container's userdata, so it survives reboots but not a re-init; reapplying it every session start is what makes it declarative.
    androidConfig = pkgs.writeShellScript "waydroid-android-config" ''
        booted=
        for _ in $(seq 1 60); do
            booted=$(/run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- getprop sys.boot_completed 2>/dev/null | tr -dc '0-9')
            [ "$booted" = "1" ] && break
            sleep 5
        done
        [ "$booted" = "1" ] || exit 0

        /run/wrappers/bin/sudo -n ${waydroidPackage}/bin/waydroid shell -- sh -c '
            pm disable com.google.android.gms/.chimera.GmsIntentOperationService
            pm disable-user --user 0 com.google.android.dialer
            pm disable-user --user 0 com.google.android.googlequicksearchbox
            pm disable-user --user 0 com.google.android.as
            pm disable-user --user 0 com.google.android.as.oss
            pm disable-user --user 0 com.google.android.apps.restore
            wm size reset
            wm density 540
            settings put global hide_error_dialogs 1
            settings put global force_resizable_activities 1
            settings put global enable_freeform_support 0
            settings put system accelerometer_rotation 0
            settings put global window_animation_scale 0
            settings put global transition_animation_scale 0
            settings put global animator_duration_scale 0
        ' > /dev/null
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
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = pkgs.waydroid-nftables; # Speaks to nftables directly rather than through the legacy iptables tables

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

            # Waydroid renders a buffer of width/height x1.5 (the output scale), and its viewport plus phoc's scaling rules present that buffer at a third
            # of its pixels: fullscreen views are never scaled and scale-to-fit never shrinks below half. 960x1920 is the one value where a third of the
            # buffer is exactly the panel, at the price of Android rendering 1440x2880 and phoc downsampling 2:1. Multi-window stays off because those
            # windows never resize after session start either, and one app filling the screen is what this hardware wants.
            for pair in ro.opengles.version=131072 ro.config.low_ram=true persist.waydroid.width=960 persist.waydroid.height=1920 persist.waydroid.multi_windows=false; do
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

            waydroid-android-config = {
                Unit = {
                    Description = "Reapply the Android-side settings that Waydroid keeps in userdata";
                    PartOf = [ "waydroid-session.service" ];
                    After = [ "waydroid-session.service" ];
                };
                Service = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    ExecStart = "${androidConfig}";
                };
                Install.WantedBy = [ "waydroid-session.service" ];
            };
        };
    };
}
