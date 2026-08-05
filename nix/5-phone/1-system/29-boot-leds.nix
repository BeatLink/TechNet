{ lib, ... }:
let
    indicators = [
        "blue"
        "green"
        "red"
    ];

    allOff = ''
        for name in ${lib.concatStringsSep " " indicators}; do
            dir=/sys/class/leds/$name:indicator
            [ -d "$dir" ] || continue
            echo none > "$dir/trigger" 2>/dev/null || true
            echo 0 > "$dir/brightness" 2>/dev/null || true
        done
    '';

    releaseOwn = ''
        for name in ${lib.concatStringsSep " " indicators}; do
            dir=/sys/class/leds/$name:indicator
            [ -d "$dir" ] || continue
            case "$(cat "$dir/trigger" 2>/dev/null)" in
                *"[timer]"*)
                    echo none > "$dir/trigger" 2>/dev/null || true
                    echo 0 > "$dir/brightness" 2>/dev/null || true
                    ;;
            esac
        done
    '';

    blink = colour: rate: ''
        ${allOff}
        dir=/sys/class/leds/${colour}:indicator
        if [ -d "$dir" ]; then
            echo timer > "$dir/trigger" 2>/dev/null || true
            echo ${toString rate} > "$dir/delay_on" 2>/dev/null || true
            echo ${toString rate} > "$dir/delay_off" 2>/dev/null || true
        fi
    '';

    phase = body: {
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = body;
    };

    failed = phase (blink "red" 200) // {
        description = "Blink the red indicator when the boot has failed";
        wantedBy = [
            "emergency.target"
            "rescue.target"
        ];
        unitConfig.DefaultDependencies = "no";
    };
in
{
    boot.initrd.systemd.services = {
        boot-led-locked = phase (blink "blue" 500) // {
            description = "Blink the blue indicator while the pools are still locked";
            wantedBy = [ "initrd.target" ];
            before = [ "zfs-import.target" ];
            unitConfig.DefaultDependencies = "no";
        };

        boot-led-unlocked = phase (blink "green" 500) // {
            description = "Blink the green indicator once the pools are unlocked";
            wantedBy = [ "initrd.target" ];
            requires = [ "zfs-import.target" ];
            after = [ "zfs-import.target" ];
            unitConfig.DefaultDependencies = "no";
        };

        boot-led-failed = failed;
    };

    systemd.services = {
        boot-led-failed = failed;

        boot-led-off = phase releaseOwn // {
            description = "Turn the indicator LEDs off once phosh is up";
            wantedBy = [ "graphical.target" ];
            after = [ "phosh.service" ];
        };
    };
}
