# Focus boost
#
# Raises the focused application's CPU, IO, memory and scheduler priority, puts
# them back when focus moves on, and freezes the units in `suspendUnits` for as
# long as any application is focused. Thor only -- it is a response to 2972MB of
# RAM and four 1.15GHz cores.
#
# Nothing in the session knows which application is focused, so this bridges the
# two halves that do:
#
#   phoc  implements zwlr_foreign_toplevel_manager_v1, which reports app_id and
#         an `activated` flag per toplevel. (It also implements the newer
#         ext_foreign_toplevel_list_v1, which lswt prefers but which carries no
#         state, so the wlr protocol is the one that answers "which one is
#         focused".)
#
#   systemd  puts every launched application in its own `app-*` unit under
#            app.slice, whose properties can be set at runtime.
#
# lswt is the client. Two things about it are load-bearing and neither is
# obvious from --help:
#
#   * `-w` alone does not report focus. The created/destroyed/app-id events are
#     gated on `mode == WATCH || debug_log`, but the state setters -- activated
#     among them -- are gated on `debug_log` only. Hence `-w --debug`.
#   * `-w` cannot be combined with `-j` or `-c`; it refuses to start. So the
#     output is the human-readable event log, parsed below, rather than JSON.
#
# stdbuf is needed because lswt writes with plain fprintf, which block-buffers
# when stdout is a pipe rather than a terminal. Without it events arrive in
# 4KB batches, which on an idle session means never.
#
# The app_id -> unit match is a heuristic and cannot be anything else: the
# protocol deliberately exposes no PID, so there is no authoritative link
# between a toplevel and a process. It works because the desktop ID lands in the
# unit name -- org.gnome.Settings becomes app-dbus\x2d:1.2\x2dorg.gnome.Settings
# .slice -- but an application whose app_id differs from its desktop ID simply
# will not match, and then nothing happens. That is the intended failure mode:
# no match means no boost, never a boost applied to the wrong unit.
#
{
    lib,
    pkgs,
    ...
}:
let
    cfg = {
        # 500 rather than a modest 2x edge: nothing on this phone is reclaiming,
        # so MemoryLow is inert and CPUWeight is the only part doing work.
        cpuWeight = 500;
        ioWeight = 200;
        # Stays behind phosh's -5 so the compositor outranks what draws into it.
        nice = -3;
        memoryLow = "384M";
        # Nothing in the session is worth freezing; only a unit that resumes cleanly mid-work belongs here.
        suspendUnits = [ ];
        # Reached through the sudo helper below, not the session's own systemctl.
        suspendSystemUnits = [ "prewarm-watch.service" ];
        # Above the 11s an app took to cold-start here, or switching apps thaws
        # and refreezes in the gap between the two.
        thawDelay = 15;
        # LXC moves the container's processes into a root-level cgroup, so Waydroid's Android has no app unit for the app_id match to find and is
        # boosted by weight on that cgroup instead. The name follows the container's, so it is fixed for as long as Waydroid calls its container waydroid.
        waydroidAppIdPrefix = "waydroid";
        waydroidCgroup = "/sys/fs/cgroup/lxc.payload.waydroid";
        # Android is a whole operating system rather than an app, and it is doing work whenever the container is up, so it keeps a share above the
        # default 100 even unfocused. Neither value goes near cpu.weight's 10000 ceiling: phosh lives in user.slice, and starving the compositor
        # freezes the screen no matter how much CPU Android is getting.
        waydroidBaseWeight = 300;
        waydroidBoostWeight = 1000;
    };

    # Takes only the two weights this daemon sets, so the NOPASSWD grant cannot be widened by argument.
    cgroupBoost = pkgs.writeShellScript "technet-focus-boost-cgroup" ''
        weight="$1"
        case "$weight" in
            ${toString cfg.waydroidBoostWeight} | ${toString cfg.waydroidBaseWeight}) ;;
            *) exit 1 ;;
        esac
        [ -e ${cfg.waydroidCgroup}/cpu.weight ] || exit 0
        echo "$weight" > ${cfg.waydroidCgroup}/cpu.weight
    '';

    # Takes only freeze|thaw and refuses any unit outside the list, so the
    # NOPASSWD grant cannot be widened by argument.
    systemFreeze = pkgs.writeShellScript "technet-focus-boost-system-freeze" ''
        verb="$1"
        unit="$2"
        case "$verb" in
            freeze|thaw) ;;
            *) exit 1 ;;
        esac
        for allowed in ${lib.escapeShellArgs cfg.suspendSystemUnits}; do
            if [ "$unit" = "$allowed" ]; then
                exec ${pkgs.systemd}/bin/systemctl "$verb" "$unit"
            fi
        done
        exit 1
    '';

    # lswt binds whichever toplevel protocol the compositor offers, and when
    # both are present the newer one wins unconditionally:
    #
    #     if ( zwlr_toplevel_manager != NULL ) used_protocol = ZWLR_FOREIGN_TOPLEVEL;
    #     if ( ext_toplevel_list    != NULL ) used_protocol = EXT_FOREIGN_TOPLEVEL;
    #
    # The second assignment is not an `else`, so ext always wins. phoc offers
    # both -- confirmed on the phone, lswt logs "Binding
    # zwlr-foreign-toplevel-manager-v1" and then "Binding
    # ext-foreign-toplevel-list-v1" -- and ext-foreign-toplevel-list-v1 carries
    # no state whatsoever. No activated flag, so no focus events, so this daemon
    # sat watching toplevels appear and never boosted one. `lswt -j` says so
    # plainly: "activated": false in the capability block, and only title and
    # app-id per toplevel.
    #
    # The wlr protocol is the one carrying state, so prefer it where both exist.
    # The ext listener stays bound and discards its own events, which upstream
    # already guards against -- its handlers return early unless ext is the
    # protocol in use.
    lswt = pkgs.lswt.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
            substituteInPlace lswt.c \
                --replace-fail \
                    "used_protocol = EXT_FOREIGN_TOPLEVEL;" \
                    "used_protocol = (zwlr_toplevel_manager == NULL) ? EXT_FOREIGN_TOPLEVEL : ZWLR_FOREIGN_TOPLEVEL;"
        '';
    });

    boostd = pkgs.writers.writePython3Bin "technet-focus-boostd" {
        flakeIgnore = [
            "E501" # line length
            "W503" # line break before a binary operator, which black prefers
        ];
    } ''
        import re
        import subprocess
        import sys
        import os
        import json
        import signal
        import threading

        BOOST = {
            "CPUWeight": "${toString cfg.cpuWeight}",
            "IOWeight": "${toString cfg.ioWeight}",
            "MemoryLow": "${cfg.memoryLow}",
        }

        # Not the values that were there before, but the defaults for an app unit.
        # Only units this daemon boosted are ever reset, so the two are the same
        # thing in practice, and reading the old values back would race with the
        # unit exiting.
        RESET = {"CPUWeight": "100", "IOWeight": "100", "MemoryLow": "0"}

        NICE = ${toString cfg.nice}

        SUSPEND = ${builtins.toJSON cfg.suspendUnits}
        SUSPEND_SYSTEM = ${builtins.toJSON cfg.suspendSystemUnits}
        THAW_DELAY = ${toString cfg.thawDelay}

        CGROUP_BOOST = "${cgroupBoost}"
        WAYDROID_BOOST = "${toString cfg.waydroidBoostWeight}"
        WAYDROID_BASE = "${toString cfg.waydroidBaseWeight}"
        WAYDROID_PREFIX = "${cfg.waydroidAppIdPrefix}"

        # systemd escapes "-" in unit names; ":" and "." are passed through.
        ESCAPED_DASH = chr(92) + "x2d"

        RE_APPID = re.compile(r"^toplevel (\d+): set app-id: '[^']*' -> '([^']*)'")
        RE_ACTIVE = re.compile(r"^\[toplevel (\d+): set activated: ([01])\]")
        RE_GONE = re.compile(r"^toplevel (\d+): destroyed")

        app_ids = {}
        active = set()
        boosted = None
        boosted_cgroup = False
        frozen = False
        thaw_timer = None
        # Reentrant because the signal handler runs in the thread that may hold it.
        freeze_lock = threading.RLock()


        def app_units():
            try:
                out = subprocess.run(
                    ["systemctl", "--user", "list-units", "--all", "--plain",
                     "--no-legend", "--output=json", "app-*"],
                    capture_output=True, text=True, timeout=5,
                )
                return [u["unit"] for u in json.loads(out.stdout or "[]")]
            except Exception:
                return []


        def find_unit(app_id):
            if not app_id:
                return None
            needle = app_id.lower()
            best = None
            for name in app_units():
                if not name.startswith("app-"):
                    continue
                if needle in name.replace(ESCAPED_DASH, "-").lower():
                    # Shortest wins: for a d-bus activated app that is the
                    # app-*.slice, which covers the service inside it.
                    if best is None or len(name) < len(best):
                        best = name
            return best


        def is_waydroid(app_id):
            return bool(app_id) and app_id.lower().startswith(WAYDROID_PREFIX)


        def cgroup_boost(want):
            subprocess.run(
                ["/run/wrappers/bin/sudo", "-n", CGROUP_BOOST,
                 WAYDROID_BOOST if want else WAYDROID_BASE],
                capture_output=True, timeout=5,
            )


        def apply(unit, props):
            if unit is None:
                return
            subprocess.run(
                ["systemctl", "--user", "set-property", "--runtime", unit]
                + [k + "=" + v for k, v in props.items()],
                capture_output=True, timeout=5,
            )


        def unit_pids(unit):
            try:
                out = subprocess.run(
                    ["systemctl", "--user", "show", "-p", "ControlGroup",
                     "--value", unit],
                    capture_output=True, text=True, timeout=5,
                )
                path = out.stdout.strip()
            except Exception:
                return []
            if not path:
                return []
            root = "/sys/fs/cgroup" + path
            pids = []
            # A slice keeps its processes in child cgroups, not its own cgroup.procs.
            for dirpath, _, _ in os.walk(root):
                try:
                    with open(os.path.join(dirpath, "cgroup.procs")) as f:
                        pids += [int(line) for line in f if line.strip()]
                except OSError:
                    continue
            return pids


        def renice(unit, value):
            for pid in unit_pids(unit):
                try:
                    os.setpriority(os.PRIO_PROCESS, pid, value)
                except OSError:
                    # Exited between listing the cgroup and setting priority.
                    pass


        def freeze(want):
            verb = "freeze" if want else "thaw"
            for unit in SUSPEND:
                subprocess.run(
                    ["systemctl", "--user", verb, unit],
                    capture_output=True, timeout=5,
                )
            for unit in SUSPEND_SYSTEM:
                subprocess.run(
                    ["/run/wrappers/bin/sudo", "-n", "${systemFreeze}", verb, unit],
                    capture_output=True, timeout=5,
                )
            print(verb + " background units", flush=True)


        def set_frozen(want, now=False):
            global frozen, thaw_timer
            if not (SUSPEND or SUSPEND_SYSTEM):
                return
            with freeze_lock:
                if thaw_timer is not None:
                    thaw_timer.cancel()
                    thaw_timer = None
                if want == frozen:
                    return
                if want or now:
                    frozen = want
                    freeze(want)
                    return
                # Thawing waits, so switching apps does not resume the background
                # units for the seconds the next one takes to appear.
                thaw_timer = threading.Timer(
                    THAW_DELAY, lambda: set_frozen(False, True)
                )
                thaw_timer.daemon = True
                thaw_timer.start()


        def focus(unit, waydroid=False):
            global boosted, boosted_cgroup
            if unit == boosted and waydroid == boosted_cgroup:
                return
            if boosted is not None:
                apply(boosted, RESET)
                renice(boosted, 0)
            if boosted_cgroup and not waydroid:
                cgroup_boost(False)
            boosted = unit
            if boosted is not None:
                apply(boosted, BOOST)
                renice(boosted, NICE)
                print("boosted " + boosted, flush=True)
            if waydroid and not boosted_cgroup:
                cgroup_boost(True)
                print("boosted waydroid cgroup", flush=True)
            boosted_cgroup = waydroid
            set_frozen(boosted is not None or waydroid)


        def cleanup(*_):
            focus(None)
            set_frozen(False, True)
            sys.exit(0)


        signal.signal(signal.SIGTERM, cleanup)
        signal.signal(signal.SIGINT, cleanup)

        # lswt refuses to start without WAYLAND_DISPLAY, and a user service does
        # not always inherit it -- it depends on the session having imported its
        # environment before this unit started. Fall back to whatever socket is
        # actually in the runtime directory.
        if "WAYLAND_DISPLAY" not in os.environ:
            rundir = os.environ.get("XDG_RUNTIME_DIR", "")
            found = sorted(
                f for f in os.listdir(rundir)
                if f.startswith("wayland-") and not f.endswith(".lock")
            ) if rundir else []
            if not found:
                print("no wayland socket found", file=sys.stderr)
                sys.exit(1)
            os.environ["WAYLAND_DISPLAY"] = found[0]

        # Establishes the unfocused share up front, so the container is above the default from the moment the session starts rather than after the
        # first focus change. Harmless when Waydroid is not running: the helper exits quietly if the cgroup is not there.
        cgroup_boost(False)

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
                    app_id = app_ids.get(m.group(1))
                    focus(find_unit(app_id), is_waydroid(app_id))
                else:
                    active.discard(m.group(1))
                    # Nothing focused means nothing to protect, and leaving the
                    # suspended units frozen would stop them for good.
                    if not active:
                        focus(None)
                continue
            m = RE_GONE.match(line)
            if m:
                app_ids.pop(m.group(1), None)
                active.discard(m.group(1))
                if not active:
                    focus(None)

        cleanup()
    '';
in
{
    config = {
        # systemd gates FreezeUnit on root and does not route it through polkit,
        # so a sudo rule is the only way to reach it from the session.
        security.sudo.extraRules = [
            {
                users = [ "beatlink" ];
                commands = [
                    {
                        command = "${systemFreeze}";
                        options = [ "NOPASSWD" ];
                    }
                    {
                        command = "${cgroupBoost}";
                        options = [ "NOPASSWD" ];
                    }
                ];
            }
        ];

        home-manager.users.beatlink = {
            systemd.user.services.technet-focus-boost = {
                Unit = {
                    Description = "Raise the focused application's cgroup limits";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };

                Service = {
                    ExecStart = "${boostd}/bin/technet-focus-boostd";
                    # Without this a SIGKILL leaves the units frozen forever.
                    ExecStopPost = pkgs.writeShellScript "technet-focus-boost-thaw" ''
                        for unit in ${lib.escapeShellArgs cfg.suspendUnits}; do
                            ${pkgs.systemd}/bin/systemctl --user thaw "$unit" || true
                        done
                        for unit in ${lib.escapeShellArgs cfg.suspendSystemUnits}; do
                            /run/wrappers/bin/sudo -n ${systemFreeze} thaw "$unit" || true
                        done
                        /run/wrappers/bin/sudo -n ${cgroupBoost} ${toString cfg.waydroidBaseWeight} || true
                    '';
                    Restart = "on-failure";
                    # The compositor may not have a socket up the instant the
                    # target is reached, and the daemon exits rather than
                    # spinning if it cannot find one.
                    RestartSec = 5;
                    # It wakes only on focus changes, so it should never be the
                    # reason anything else waits.
                    Nice = 5;
                    CPUWeight = 20;
                    # Renicing the focused app below 0 needs this raised; without
                    # it the boost silently does nothing but the weights.
                    LimitNICE = 20 - cfg.nice;
                };

                Install.WantedBy = [ "graphical-session.target" ];
            };
        };
    };
}
