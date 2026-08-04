# Focus boost
#
# Raises the resource limits of whichever application currently has focus, and
# puts them back when focus moves on. Off by default; Thor turns it on.
#
# The point is not CPU. phosh already runs at Nice -5 and CPUWeight 1000, and
# the things that compete with it are quota'd. The point is `MemoryLow`, for the
# reason 5-phone/1-system/18-performance.nix already gives about phosh: a
# high-priority process waits on a page fault exactly as long as a low-priority
# one, so priority cannot touch a stall caused by reclaim, and only a memory
# floor can. IOWeight matters here too -- Thor's SD card saturates at 23.9MB/s
# measured, which is a queue worth having a share of.
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
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.desktop.focusBoost;

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

        # systemd escapes "-" in unit names; ":" and "." are passed through.
        ESCAPED_DASH = chr(92) + "x2d"

        RE_APPID = re.compile(r"^toplevel (\d+): set app-id: '[^']*' -> '([^']*)'")
        RE_ACTIVE = re.compile(r"^\[toplevel (\d+): set activated: ([01])\]")
        RE_GONE = re.compile(r"^toplevel (\d+): destroyed")

        app_ids = {}
        boosted = None


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


        def apply(unit, props):
            if unit is None:
                return
            subprocess.run(
                ["systemctl", "--user", "set-property", "--runtime", unit]
                + [k + "=" + v for k, v in props.items()],
                capture_output=True, timeout=5,
            )


        def focus(unit):
            global boosted
            if unit == boosted:
                return
            if boosted is not None:
                apply(boosted, RESET)
            boosted = unit
            if boosted is not None:
                apply(boosted, BOOST)
                print("boosted " + boosted, flush=True)


        def cleanup(*_):
            focus(None)
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

        proc = subprocess.Popen(
            ["${pkgs.coreutils}/bin/stdbuf", "-oL", "${pkgs.lswt}/bin/lswt", "-w", "--debug"],
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
                    focus(find_unit(app_ids.get(m.group(1))))
                continue
            m = RE_GONE.match(line)
            if m:
                app_ids.pop(m.group(1), None)

        cleanup()
    '';
in
{
    options.technet.desktop.focusBoost = {
        enable = lib.mkEnableOption ''
            raising the focused application's cgroup limits.

            Worth having on a memory-constrained host and pointless on one with
            RAM to spare, so it is opt-in per host rather than on for everything
            that imports the desktop layer
        '';

        cpuWeight = lib.mkOption {
            type = lib.types.ints.between 1 10000;
            default = 200;
            description = ''
                CPUWeight for the focused application, against a default of 100.
                Deliberately modest: the compositor sits at 1000 and should stay
                ahead of the application drawing into it.
            '';
        };

        ioWeight = lib.mkOption {
            type = lib.types.ints.between 1 10000;
            default = 200;
            description = "IOWeight for the focused application, against a default of 100.";
        };

        memoryLow = lib.mkOption {
            type = lib.types.str;
            default = "384M";
            description = ''
                Memory the kernel should avoid reclaiming from the focused
                application. Best-effort rather than a reservation -- MemoryLow,
                not MemoryMin -- so setting it higher than the host can satisfy
                degrades rather than trading a freeze for an OOM kill.
            '';
        };
    };

    config = lib.mkIf cfg.enable {
        home-manager.users.beatlink = {
            systemd.user.services.technet-focus-boost = {
                Unit = {
                    Description = "Raise the focused application's cgroup limits";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };

                Service = {
                    ExecStart = "${boostd}/bin/technet-focus-boostd";
                    Restart = "on-failure";
                    # The compositor may not have a socket up the instant the
                    # target is reached, and the daemon exits rather than
                    # spinning if it cannot find one.
                    RestartSec = 5;
                    # It wakes only on focus changes, so it should never be the
                    # reason anything else waits.
                    Nice = 5;
                    CPUWeight = 20;
                };

                Install.WantedBy = [ "graphical-session.target" ];
            };
        };
    };
}
