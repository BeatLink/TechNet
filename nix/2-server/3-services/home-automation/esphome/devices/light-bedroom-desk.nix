# Bedroom desk light -- Athom RGBCT bulb.
{
    substitutions.name = "light-bedroom-desk";
    packages.common = "!include .2-base-bulb.yaml";
    # Cap output at 50%. In the desk lamp enclosure the bulb overheats at full
    # power, which knocks it off wifi.
    output = [
        {
            id = "!extend white_output";
            max_power = 0.5;
        }
    ];
}
