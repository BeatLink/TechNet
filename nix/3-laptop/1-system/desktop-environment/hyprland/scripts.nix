# Helper Scripts
#
# Small scripts that back the waybar modules and hot corners. They are exposed through pkgs by the overlay below
# so that every module referring to them resolves to the same store path.
#
# The overlay for the overview and show desktop scripts lives in ./overview.nix, next to the module that
# documents why they exist.
#

{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            # Replaces the weather@mockturtl applet in the Cinnamon panel. That applet was configured to use the
            # OpenMeteo provider at 18.0028,-76.7897 with automatic units, so the same provider and coordinates
            # are used here. OpenMeteo needs no API key, which is why the applet defaulted to it.
            #
            # Waybar expects a JSON object on stdout with text, tooltip and class fields.
            hypr-weather = final.writeShellApplication {
                name = "hypr-weather";
                runtimeInputs = with final; [
                    curl
                    jq
                ];
                text = ''
                    latitude=18.0028
                    longitude=-76.7897

                    response=$(
                        curl -fsS --max-time 15 \
                            "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code&temperature_unit=celsius&timezone=auto" \
                            2>/dev/null
                    ) || {
                        jq -nc '{text: "", tooltip: "Weather unavailable", class: "offline"}'
                        exit 0
                    }

                    # WMO weather interpretation codes, as used by OpenMeteo. Grouped rather than enumerated so
                    # that unlisted codes still fall through to a sensible description.
                    printf '%s' "$response" | jq -c '
                        .current as $c
                        | ($c.weather_code // -1) as $code
                        | (
                            if   $code == 0            then "Clear"
                            elif $code <= 2            then "Partly cloudy"
                            elif $code == 3            then "Overcast"
                            elif $code <= 48           then "Fog"
                            elif $code <= 57           then "Drizzle"
                            elif $code <= 67           then "Rain"
                            elif $code <= 77           then "Snow"
                            elif $code <= 82           then "Showers"
                            elif $code <= 86           then "Snow showers"
                            elif $code <= 99           then "Thunderstorm"
                            else "Unknown"
                            end
                        ) as $desc
                        | {
                            text: "\($desc) \($c.temperature_2m | round)°C",
                            tooltip: "\($desc)\nTemperature: \($c.temperature_2m)°C\nFeels like: \($c.apparent_temperature)°C\nHumidity: \($c.relative_humidity_2m)%",
                            class: "weather"
                        }
                    '
                '';
            };
        })
    ];
}
