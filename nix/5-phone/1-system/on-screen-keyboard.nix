# On-screen keyboard ################################################################################################################################
#
# phosh shows its keyboard whenever screen-keyboard-enabled is set, with no notion of a physical one being attached, so this follows the input devices
# and toggles that key. The keyboard case, a USB keyboard and a 2.4GHz dongle all look the same from here: a device that reports letter keys.
#
{ pkgs, ... }:
let
    # ID_INPUT_KEYBOARD is too loose on this hardware -- the power button and gpio-keys both claim it -- so a device has to report KEY_A and KEY_Z to
    # count. capabilities/key is hex words with the low bits last, and both those keys live in that final word.
    oskAuto = pkgs.writers.writePython3Bin "osk-auto" { flakeIgnore = [ "E501" ]; } ''
        import glob
        import subprocess
        import threading

        KEY = "/org/gnome/desktop/a11y/applications/screen-keyboard-enabled"
        KEY_A = 30
        KEY_Z = 44
        # A dongle enumerates as several devices in quick succession, and toggling on each one makes the keyboard flicker.
        SETTLE = 1.0

        state = {"timer": None, "written": None}


        def is_keyboard(path):
            try:
                with open(path) as f:
                    words = f.read().split()
            except OSError:
                return False
            if not words:
                return False
            low = int(words[-1], 16)
            return bool(low & (1 << KEY_A)) and bool(low & (1 << KEY_Z))


        def physical_keyboard():
            return any(is_keyboard(p) for p in glob.glob("/sys/class/input/event*/device/capabilities/key"))


        def refresh():
            wanted = "false" if physical_keyboard() else "true"
            if wanted == state["written"]:
                return
            subprocess.run(["${pkgs.dconf}/bin/dconf", "write", KEY, wanted], capture_output=True, timeout=10)
            state["written"] = wanted
            print("screen keyboard " + ("off" if wanted == "false" else "on"), flush=True)


        def schedule():
            if state["timer"] is not None:
                state["timer"].cancel()
            state["timer"] = threading.Timer(SETTLE, refresh)
            state["timer"].daemon = True
            state["timer"].start()


        refresh()

        monitor = subprocess.Popen(
            ["${pkgs.systemd}/bin/udevadm", "monitor", "--udev", "--subsystem-match=input"],
            stdout=subprocess.PIPE, text=True,
        )
        for line in monitor.stdout:
            if " add " in line or " remove " in line or " bind " in line or " unbind " in line:
                schedule()
    '';
in
{
    home-manager.users.beatlink = {
        systemd.user.services.osk-auto = {
            Unit = {
                Description = "Hide the on-screen keyboard while a physical keyboard is attached";
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
            };
            Service = {
                ExecStart = "${oskAuto}/bin/osk-auto";
                # Leaving it off would strand the phone with no keyboard at all once the physical one is gone.
                ExecStopPost = "${pkgs.dconf}/bin/dconf write /org/gnome/desktop/a11y/applications/screen-keyboard-enabled true";
                Restart = "on-failure";
                RestartSec = 10;
            };
            Install.WantedBy = [ "graphical-session.target" ];
        };
    };
}
