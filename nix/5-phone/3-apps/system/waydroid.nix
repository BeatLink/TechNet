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

    # Rotation has to belong to exactly one of the two stacks or both apply a quarter turn. While a Waydroid window is focused this takes phosh's
    # rotation lock and drives Android's own rotation from the sensor; the moment focus leaves, the lock goes back and phosh rotates normally again.
    rotationBridge = pkgs.writers.writePython3Bin "waydroid-rotation" {
        libraries = [ pkgs.python3Packages.pygobject3 ];
        flakeIgnore = [ "E501" ];
    } ''
        import re
        import subprocess
        import threading
        import gi
        gi.require_version("Gio", "2.0")
        from gi.repository import Gio, GLib  # noqa: E402

        LOCK = "/org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock"
        # left-up and right-up are the other way round from the names: the accelerometer's idea of which edge is up is mirrored against Android's rotations.
        ORIENTATION = {"normal": "0", "left-up": "3", "bottom-up": "2", "right-up": "1"}
        PREFIX = "waydroid"
        # The accelerometer flaps between two readings when the phone is near flat, and every flip costs a re-layout, so a reading has to hold.
        SETTLE = 3.0

        WAYDROID = ["/run/wrappers/bin/sudo", "-n", "${waydroidPackage}/bin/waydroid", "shell", "--"]

        state = {"focused": False, "orientation": None, "timer": None, "applied": None}
        lock = threading.RLock()

        RE_APPID = re.compile(r"^toplevel (\d+): set app-id: '[^']*' -> '([^']*)'")
        RE_ACTIVE = re.compile(r"^\[toplevel (\d+): set activated: ([01])\]")
        RE_GONE = re.compile(r"^toplevel (\d+): destroyed")


        def rotation_lock(held):
            subprocess.run(["${pkgs.dconf}/bin/dconf", "write", LOCK, "true" if held else "false"], capture_output=True, timeout=10)


        def apply(orientation):
            rotation = ORIENTATION.get(orientation or "")
            if rotation is None or not state["focused"] or rotation == state["applied"]:
                return
            subprocess.run(WAYDROID + ["settings", "put", "system", "user_rotation", rotation], capture_output=True, timeout=30)
            state["applied"] = rotation
            print("rotation " + rotation + " (" + orientation + ")", flush=True)


        def schedule(orientation):
            with lock:
                state["orientation"] = orientation
                if state["timer"] is not None:
                    state["timer"].cancel()
                state["timer"] = threading.Timer(SETTLE, lambda: apply(orientation))
                state["timer"].daemon = True
                state["timer"].start()


        def focus(is_waydroid):
            with lock:
                if is_waydroid == state["focused"]:
                    return
                state["focused"] = is_waydroid
                rotation_lock(is_waydroid)
                print(("held" if is_waydroid else "released") + " rotation lock", flush=True)
                if is_waydroid:
                    state["applied"] = None
                    apply(state["orientation"])


        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
        proxy = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None,
            "net.hadess.SensorProxy", "/net/hadess/SensorProxy",
            "net.hadess.SensorProxy", None,
        )
        # The claim lasts as long as this connection, and without one the proxy stops reporting when phosh drops its own.
        proxy.call_sync("ClaimAccelerometer", None, Gio.DBusCallFlags.NONE, -1, None)

        cached = proxy.get_cached_property("AccelerometerOrientation")
        state["orientation"] = cached.get_string() if cached is not None else None

        proxy.connect(
            "g-properties-changed",
            lambda _p, changed, _inv: (
                schedule(changed["AccelerometerOrientation"])
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
                        focus((app_ids.get(m.group(1)) or "").lower().startswith(PREFIX))
                    else:
                        active.discard(m.group(1))
                        if not active:
                            focus(False)
                    continue
                m = RE_GONE.match(line)
                if m:
                    app_ids.pop(m.group(1), None)
                    active.discard(m.group(1))
                    if not active:
                        focus(False)


        thread = threading.Thread(target=watch_toplevels, daemon=True)
        thread.start()

        GLib.MainLoop().run()
    '';

    # Rotation is phosh's job: it turns the output, and Android is pinned to rotation 0 so the two do not each apply a quarter turn. What Android is
    # asked for instead is that apps reflow into whatever window they are given, which is what force_resizable_activities does to those declaring otherwise.
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
            wm size 720x1440
            wm density 270
            settings put global hide_error_dialogs 1
            settings put global force_resizable_activities 1
            settings put global enable_freeform_support 0
            settings put system accelerometer_rotation 0
            settings put system user_rotation 0
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

    environment.systemPackages = [ pkgs.wl-clipboard ]; # The clipboard bridge shells out to wl-copy and wl-paste, and does nothing without them

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

            # Left to itself Waydroid takes the panel's long edge as the width and comes up 1440x649 landscape, which every app then draws for. Multi-window
            # is off because it gives each app a freeform window on a phone-sized panel, and one app filling the screen is what this hardware wants.
            for pair in ro.opengles.version=131072 ro.config.low_ram=true persist.waydroid.width=720 persist.waydroid.height=1440 persist.waydroid.multi_windows=false; do
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
                    Description = "Hand rotation to Android while a Waydroid window is focused";
                    PartOf = [ "waydroid-session.service" ];
                    After = [ "waydroid-android-config.service" ];
                };
                Service = {
                    ExecStart = "${rotationBridge}/bin/waydroid-rotation";
                    # Leaving the lock held would strand phosh in whatever orientation it was in when this stopped.
                    ExecStopPost = "${pkgs.dconf}/bin/dconf write /org/gnome/settings-daemon/peripherals/touchscreen/orientation-lock false";
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
