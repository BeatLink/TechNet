{ lib, ... }:
let
    supply = "/sys/class/power_supply";

    caseInputLimit = 1500000;
    holdLow = 75;
    holdHigh = 80;
    interval = 30;
in
{
    systemd.services.charge-hold = {
        description = "Draw the keyboard case's full current and hold the battery between ${toString holdLow}% and ${toString holdHigh}%";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];

        serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = 10;
        };

        script = ''
            set -u

            behaviour=${supply}/axp20x-battery/charge_behaviour

            while :; do
                if [ "$(cat ${supply}/ip5xxx-boost/online 2>/dev/null || echo 0)" = 1 ]; then
                    limit="$(cat ${supply}/axp20x-usb/input_current_limit 2>/dev/null || echo 0)"
                    if [ "$limit" != ${toString caseInputLimit} ]; then
                        echo "charge-hold: keyboard case attached, raising input limit from $limit to ${toString caseInputLimit}"
                        echo ${toString caseInputLimit} > ${supply}/axp20x-usb/input_current_limit || true
                    fi
                fi

                capacity="$(cat ${supply}/axp20x-battery/capacity 2>/dev/null || echo -1)"
                active="$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' "$behaviour" 2>/dev/null || echo auto)"

                if [ "$capacity" -ge ${toString holdHigh} ]; then
                    want=inhibit-charge
                elif [ "$capacity" -lt ${toString holdLow} ] && [ "$capacity" -ge 0 ]; then
                    want=auto
                else
                    want="$active"
                fi

                if [ "$want" != "$active" ]; then
                    echo "charge-hold: battery at $capacity%, switching charging from $active to $want"
                    echo "$want" > "$behaviour" || true
                fi

                sleep ${toString interval}
            done
        '';

        postStop = ''
            echo auto > ${supply}/axp20x-battery/charge_behaviour || true
        '';
    };
}
