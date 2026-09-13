# Bedroom fan -- a Home Assistant package that drives the dumb IR ceiling fan.
#
# The fan only understands toggle pulses from the `ir-fan` blaster, and its wall
# socket is the separate `socket-fan` plug. This package stitches the two into
# one fan entity with a power-on choice, all driven from Home Assistant.
let
    socket = "switch.fan_plug_switch";
    socketUptime = "sensor.fan_plug_uptime";
    togglePower = "button.fan_remote_ir_fan_toggle_power";
    toggleSpeed = "button.fan_remote_ir_fan_toggle_speed";
    running = "input_boolean.bedroom_fan_running";
    speed = "input_number.bedroom_fan_speed";
    powerOnState = "input_select.bedroom_fan_power_on_state";

    setSpeed = level: {
        action = "script.bedroom_fan_set_speed";
        data.level = level;
    };
    turnOff = {
        action = "script.bedroom_fan_turn_off";
    };
    press = entity: {
        action = "button.press";
        target.entity_id = entity;
    };
    wait = {
        delay.seconds = 1;
    };

    # True when the socket's uptime text like "3d 0h 22m" reads under two minutes; an unavailable or unparsed value never counts as fresh.
    socketJustBooted = ''
        {% set u = states('${socketUptime}') %}
        {% set ns = namespace(s = 0, found = false) %}
        {% for unit, mult in [('d', 86400), ('h', 3600), ('m', 60), ('s', 1)] %}
          {% set found = u | regex_findall('([0-9]+)' ~ unit) %}
          {% if found %}{% set ns.s = ns.s + (found[0] | int) * mult %}{% set ns.found = true %}{% endif %}
        {% endfor %}
        {{ ns.found and ns.s < 120 }}
    '';
in
{
    # State the scripts keep between runs ------------------------------------------------------------------------------------------------------------
    input_boolean.bedroom_fan_running = {
        name = "Bedroom Fan Running";
        icon = "mdi:fan";
    };
    input_number.bedroom_fan_speed = {
        name = "Bedroom Fan Speed";
        icon = "mdi:fan";
        min = 1;
        max = 4;
        step = 1;
        mode = "box";
    };
    input_select.bedroom_fan_power_on_state = {
        name = "Bedroom Fan Power On State";
        icon = "mdi:power-settings";
        options = [
            "Off"
            "Restore Last State"
            "Speed 1"
            "Speed 2"
            "Speed 3"
            "Speed 4"
        ];
    };

    # The fan entity ---------------------------------------------------------------------------------------------------------------------------------
    template = [
        {
            fan = [
                {
                    name = "Bedroom Fan";
                    unique_id = "bedroom_fan";
                    speed_count = 4;
                    state = "{{ is_state('${socket}', 'on') and is_state('${running}', 'on') }}";
                    percentage = "{{ states('${speed}') | int(4) * 25 }}";
                    turn_on = [ (setSpeed "{{ states('${speed}') | int(4) }}") ];
                    turn_off = [ turnOff ];
                    set_percentage = [
                        {
                            "if" = [
                                {
                                    condition = "template";
                                    value_template = "{{ percentage | int == 0 }}";
                                }
                            ];
                            "then" = [ turnOff ];
                            "else" = [ (setSpeed "{{ (percentage | int / 25) | round(0) | int }}") ];
                        }
                    ];
                }
            ];
        }
    ];

    # Scripts ----------------------------------------------------------------------------------------------------------------------------------------
    script = {
        # Drives the fan to an absolute speed: the remote only toggles, so power-cycling the socket resets it to speed 4 and each press steps down.
        bedroom_fan_set_speed = {
            alias = "Bedroom Fan Set Speed";
            icon = "mdi:fan";
            mode = "restart";
            fields.level = {
                description = "Speed level 1 to 4";
                example = 4;
                selector.number = {
                    min = 1;
                    max = 4;
                };
            };
            sequence = [
                {
                    action = "input_number.set_value";
                    target.entity_id = speed;
                    data.value = "{{ level | int }}";
                }
                {
                    action = "input_boolean.turn_on";
                    target.entity_id = running;
                }
                {
                    action = "switch.turn_off";
                    target.entity_id = socket;
                }
                wait
                {
                    action = "switch.turn_on";
                    target.entity_id = socket;
                }
                wait
                (press togglePower)
                wait
                {
                    repeat = {
                        count = "{{ 4 - level | int }}";
                        sequence = [
                            (press toggleSpeed)
                            wait
                        ];
                    };
                }
            ];
        };
        bedroom_fan_turn_off = {
            alias = "Bedroom Fan Turn Off";
            icon = "mdi:fan-off";
            mode = "single";
            sequence = [
                {
                    action = "input_boolean.turn_off";
                    target.entity_id = running;
                }
                {
                    action = "switch.turn_off";
                    target.entity_id = socket;
                }
            ];
        };
    };

    # Automations ------------------------------------------------------------------------------------------------------------------------------------
    automation = [
        # The socket coming back with a fresh uptime is how a power cut looks from here.
        {
            id = "bedroom_fan_power_on";
            alias = "Bedroom Fan Power On";
            mode = "single";
            triggers = [
                {
                    trigger = "state";
                    entity_id = socket;
                    from = "unavailable";
                }
            ];
            actions = [
                # A reconnect after a Home Assistant restart still shows the old uptime, so this times out and stops.
                {
                    wait_template = socketJustBooted;
                    timeout = "00:01:30";
                    continue_on_timeout = false;
                }
                {
                    wait_template = "{{ not is_state('${togglePower}', 'unavailable') }}";
                    timeout = "00:02:00";
                    continue_on_timeout = false;
                }
                {
                    choose = [
                        {
                            conditions = [
                                {
                                    condition = "state";
                                    entity_id = powerOnState;
                                    state = "Off";
                                }
                            ];
                            sequence = [ turnOff ];
                        }
                        {
                            conditions = [
                                {
                                    condition = "state";
                                    entity_id = powerOnState;
                                    state = "Restore Last State";
                                }
                                {
                                    condition = "state";
                                    entity_id = running;
                                    state = "on";
                                }
                            ];
                            sequence = [ (setSpeed "{{ states('${speed}') | int(4) }}") ];
                        }
                        {
                            conditions = [
                                {
                                    condition = "template";
                                    value_template = "{{ states('${powerOnState}').startswith('Speed ') }}";
                                }
                            ];
                            sequence = [ (setSpeed "{{ states('${powerOnState}')[6:] | int }}") ];
                        }
                    ];
                }
            ];
        }
        # A socket switched off by anything but the speed script means the fan is off.
        {
            id = "bedroom_fan_socket_off";
            alias = "Bedroom Fan Socket Off";
            mode = "single";
            triggers = [
                {
                    trigger = "state";
                    entity_id = socket;
                    to = "off";
                }
            ];
            conditions = [
                {
                    condition = "state";
                    entity_id = "script.bedroom_fan_set_speed";
                    state = "off";
                }
            ];
            actions = [
                {
                    action = "input_boolean.turn_off";
                    target.entity_id = running;
                }
            ];
        }
    ];
}
