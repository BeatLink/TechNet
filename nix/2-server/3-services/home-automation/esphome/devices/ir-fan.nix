# Bedroom fan -- ESP8285 IR blaster driving a 4-speed ceiling fan.
#
# The fan itself is dumb: it only understands IR toggle pulses, and its wall
# socket is a separate `socket-fan` plug. This config stitches the two into one
# Home Assistant fan entity:
#
#   * `virtual_fan` is the entity HA sees.
#   * `fan_socket_switch` mirrors the wall socket over HTTP.
#   * `sync_fan_speed` walks the remote's toggle-only speed cycle to reach an
#     absolute speed, by power-cycling the socket and counting button presses.
#   * `high_speed_socket_poller` re-reads the socket once every 2s so external
#     changes to the plug show up on the fan entity.
{ lib, ... }:
let
    # Pronto codes captured from the original fan remote.
    prontoPower = "0000 006D 0054 0000 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0031 0010 0030 0011 0030 0010 0031 0010 0031 0010 0031 002F 0115 0030 0010 0030 0010 0011 0030 0030 0010 0030 0011 0011 0031 000F 0031 0011 0030 0010 0031 0011 0030 0010 0031 0030 0115 002F 0011 002F 0011 0010 0031 002F 0011 002F 0011 0010 0031 0010 0031 0010 0031 0010 0031 0010 0031 0010 0031 0030 0115 0030 0010 0030 0010 0010 0031 002F 0011 0030 0010 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0030 0115 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0010 0031 0030 0115 0030 0010 0031 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0030 0115 0030 0011 0030 0011 0011 0030 0030 0011 0030 0011 0010 0031 0011 0030 0011 0030 0011 0030 0011 0030 0010 0030 002F 0181";
    prontoSpeed = "0000 006D 006C 0000 0030 0011 0030 0010 0010 0031 0030 0010 0030 0010 0011 0030 0010 0031 0010 0031 0010 0031 0010 0031 0030 0010 0011 0134 0030 0011 0030 0010 0011 0030 0030 0010 002F 0011 0010 0031 0010 0031 0011 0030 0010 0031 0010 0032 002E 0011 0011 0134 0030 0011 0030 0011 0010 0031 0030 0010 0030 0011 0010 0031 0010 0031 0010 0031 0010 0031 0010 0031 0030 0010 0010 0135 002F 0011 002F 0011 0010 0031 002F 0011 0030 0011 0010 0031 0010 0031 0010 0031 0010 0031 0010 0031 002F 0011 0010 0135 0030 0011 0030 0010 0010 0031 0030 0011 0030 0011 0010 0031 0010 0031 0010 0031 0010 0031 0010 0031 0030 0010 0011 0134 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0011 0030 0010 0031 0030 0010 0011 0134 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0031 0010 0011 0134 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0011 0030 0011 0030 0030 0011 0011 0134 0030 0011 0030 0011 0011 0030 0030 0011 0030 0011 0010 0030 000F 0031 0010 0031 0010 0032 0010 0031 002E 0012 000F 0181";
    prontoTime = "0000 006D 0060 0000 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0030 0010 0011 0030 0011 0030 0010 0135 0030 0010 0030 0010 0011 0030 0030 0010 0030 0011 0011 0030 0010 0031 0011 0030 0030 0010 0010 0031 0010 0031 0011 0134 002F 0011 002F 0011 0011 0030 0030 0011 002F 0011 0010 0031 0011 0030 0011 0030 002F 0011 0010 0031 0011 0030 0010 0135 002F 0011 0030 0010 0010 0031 002F 0011 0030 0010 0011 0030 0010 0031 0010 0031 002F 0011 0011 0030 0010 0031 0010 0135 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0030 0010 0011 0030 0011 0030 0011 0134 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0010 0031 0030 0010 0011 0030 0011 0030 0011 0134 0030 0010 0030 0010 0011 0030 0030 0010 0030 0010 0011 0030 0011 0030 0011 0030 0030 0010 0011 0030 0011 0030 0011 0134 0030 0011 0030 0011 0011 0030 0030 0011 0030 0011 0011 0030 0011 0030 0010 0030 002F 0012 0010 0031 0010 0030 0010 0181";
in
{
    substitutions = {
        name = "ir-fan";
        room = "Bedroom";

        # Infrastructure credentials, kept out of the lambda bodies below.
        socket_ip = "socket-fan.lan";
        web_user = "!secret web_username";
        web_password = "!secret web_password";
    };

    packages.common = "!include 2-base-ir.yaml";

    http_request = {
        timeout = "1s";
        verify_ssl = false;
    };

    esphome = {
        name = "ir-fan";
        on_boot = {
            # Runs late in the boot sequence, once wifi is stable.
            priority = -100;
            "then" = [ { "script.execute" = "high_speed_socket_poller"; } ];
        };
    };

    globals = [
        {
            id = "current_preset";
            type = "std::string";
            initial_value = "\"max\"";
        }
    ];

    fan = [
        {
            platform = "template";
            name = "Bedroom Fan";
            id = "virtual_fan";
            speed_count = 4;

            on_turn_on."then" = [ { "switch.turn_on" = "fan_socket_switch"; } ];
            on_turn_off."then" = [ { "switch.turn_off" = "fan_socket_switch"; } ];

            on_speed_set."then" = [
                {
                    "script.execute" = {
                        id = "sync_fan_speed";
                        target_speed_level = "!lambda return x;";
                    };
                }
            ];
        }
    ];

    script = [
        # Mirrors the wall socket's state onto `fan_socket_switch`.
        {
            id = "high_speed_socket_poller";
            mode = "single";
            "then" = [
                {
                    "http_request.get" = {
                        url = ''!lambda return "http://''${web_user}:''${web_password}@''${socket_ip}/switch/Switch";'';
                        capture_response = true;
                        on_response."then" = [
                            {
                                lambda = lib.removeSuffix "
" ''
                                    if (response->status_code == 200) {
                                      json::parse_json(body, [](JsonObject root) -> bool {
                                        if (root.containsKey("value")) {
                                          id(fan_socket_switch).publish_state(root["value"]);
                                          return true;
                                        }
                                        return false;
                                      });
                                    }
                                '';
                            }
                        ];
                        on_error."then" = [ { "logger.log" = "Socket poll failed, network busy."; } ];
                    };
                }
                { delay = "2s"; }
                { "script.execute" = "high_speed_socket_poller"; }
            ];
        }

        # Drives the fan to an absolute speed. The remote only has a toggle, so
        # this power-cycles the socket to reset to a known state (speed 4) and
        # then presses the speed button (4 - target) times.
        {
            id = "sync_fan_speed";
            parameters.target_speed_level = "int";
            mode = "restart";
            "then" = [
                { "switch.turn_off" = "fan_socket_switch"; }
                { delay = "1s"; }
                { "switch.turn_on" = "fan_socket_switch"; }
                { delay = "1s"; }
                { "button.press" = "toggle_power"; }
                { delay = "1s"; }
                {
                    "if" = {
                        condition.lambda = "return target_speed_level <= 3;";
                        "then" = [
                            { "button.press" = "toggle_speed"; }
                            { delay = "1s"; }
                        ];
                    };
                }
                {
                    "if" = {
                        condition.lambda = "return target_speed_level <= 2;";
                        "then" = [
                            { "button.press" = "toggle_speed"; }
                            { delay = "1s"; }
                        ];
                    };
                }
                {
                    "if" = {
                        condition.lambda = "return target_speed_level == 1;";
                        "then" = [
                            { "button.press" = "toggle_speed"; }
                            { delay = "1s"; }
                        ];
                    };
                }
            ];
        }
    ];

    # Controls -----------------------------------------------------------------
    switch = [
        {
            platform = "template";
            name = "Socket Fan Wall Power";
            id = "fan_socket_switch";
            optimistic = true;
            # False because the poller above gives us real state tracking.
            assumed_state = false;
            icon = "mdi:power-socket-us";

            on_turn_on."then" = [
                {
                    lambda = lib.removeSuffix "
" ''
                        id(virtual_fan).state = true;
                        id(virtual_fan).publish_state();
                    '';
                }
            ];
            on_turn_off."then" = [
                {
                    lambda = lib.removeSuffix "
" ''
                        id(virtual_fan).state = false;
                        id(virtual_fan).publish_state();
                    '';
                }
            ];

            turn_on_action = [
                {
                    "http_request.post".url =
                        ''!lambda return "http://''${web_user}:''${web_password}@''${socket_ip}/switch/Switch/turn_on";'';
                }
            ];
            turn_off_action = [
                {
                    "http_request.post".url =
                        ''!lambda return "http://''${web_user}:''${web_password}@''${socket_ip}/switch/Switch/turn_off";'';
                }
            ];
        }
    ];

    button = [
        {
            platform = "template";
            name = "Fan Toggle Power";
            id = "toggle_power";
            on_press = [
                { "logger.log" = "Fan Toggle Power"; }
                { "remote_transmitter.transmit_pronto".data = prontoPower; }
            ];
        }
        {
            platform = "template";
            name = "Fan Toggle Speed";
            id = "toggle_speed";
            on_press = [
                { "logger.log" = "Fan Toggle Speed"; }
                { "remote_transmitter.transmit_pronto".data = prontoSpeed; }
            ];
        }
        {
            platform = "template";
            name = "Fan Toggle Time";
            id = "toggle_time";
            on_press = [
                { "logger.log" = "Fan Toggle Time"; }
                { "remote_transmitter.transmit_pronto".data = prontoTime; }
            ];
        }
    ];
}
