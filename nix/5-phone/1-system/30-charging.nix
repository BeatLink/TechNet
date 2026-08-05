{ pkgs, ... }:
let
    caseInputLimit = 1500000;
    holdLow = 75;
    holdHigh = 80;
    interval = 30;

    chargeHold = pkgs.writers.writePython3 "charge-hold" { } ''
        import time
        from pathlib import Path

        SUPPLY = Path("/sys/class/power_supply")
        PHONE = SUPPLY / "axp20x-battery"
        PHONE_INPUT = SUPPLY / "axp20x-usb"
        CASE = SUPPLY / "ip5xxx-battery"
        CASE_BOOST = SUPPLY / "ip5xxx-boost"

        CASE_INPUT_LIMIT = ${toString caseInputLimit}
        HOLD_LOW = ${toString holdLow}
        HOLD_HIGH = ${toString holdHigh}
        INTERVAL = ${toString interval}


        def read(path):
            try:
                return path.read_text().strip()
            except OSError:
                return None


        def write(path, value):
            try:
                path.write_text(str(value))
            except OSError:
                log("could not write " + str(value) + " to " + str(path))


        def log(message):
            print("charge-hold: " + message, flush=True)


        def selected_behaviour(path):
            text = read(path)
            if text is None:
                return None
            for field in text.split():
                if field.startswith("[") and field.endswith("]"):
                    return field[1:-1]
            return None


        def set_behaviour(path, wanted, subject):
            current = selected_behaviour(path)
            if current is None or current == wanted:
                return
            log(subject + " charging: " + current + " -> " + wanted)
            write(path, wanted)


        def take_the_cases_full_current():
            if read(CASE_BOOST / "online") != "1":
                return
            limit = PHONE_INPUT / "input_current_limit"
            if read(limit) != str(CASE_INPUT_LIMIT):
                log("case attached, input limit " + str(read(limit))
                    + " -> " + str(CASE_INPUT_LIMIT))
                write(limit, CASE_INPUT_LIMIT)


        def phone_capacity():
            value = read(PHONE / "capacity")
            if value is None or not value.isdigit():
                return None
            return int(value)


        def hold_the_phone_in_band(capacity):
            if capacity >= HOLD_HIGH:
                wanted = "inhibit-charge"
            elif capacity < HOLD_LOW:
                wanted = "auto"
            else:
                return
            set_behaviour(PHONE / "charge_behaviour", wanted,
                          "phone at " + str(capacity) + "%,")


        def charge_the_phone_before_the_case(capacity):
            behaviour = CASE / "charge_behaviour"
            if not behaviour.exists():
                return
            wanted = "inhibit-charge" if capacity < HOLD_HIGH else "auto"
            set_behaviour(behaviour, wanted,
                          "phone at " + str(capacity) + "%, case")


        def main():
            while True:
                take_the_cases_full_current()
                capacity = phone_capacity()
                if capacity is not None:
                    hold_the_phone_in_band(capacity)
                    charge_the_phone_before_the_case(capacity)
                time.sleep(INTERVAL)


        main()
    '';
in
{
    systemd.services.charge-hold = {
        description = "Draw the keyboard case's full current, charge the phone before the case, and hold it between ${toString holdLow}% and ${toString holdHigh}%";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];

        serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 10;
            ExecStart = chargeHold;
        };

        postStop = ''
            echo auto > /sys/class/power_supply/axp20x-battery/charge_behaviour || true
            if [ -e /sys/class/power_supply/ip5xxx-battery/charge_behaviour ]; then
                echo auto > /sys/class/power_supply/ip5xxx-battery/charge_behaviour || true
            fi
        '';
    };
}
