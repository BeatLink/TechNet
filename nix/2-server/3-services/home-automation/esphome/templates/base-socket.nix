# Hardware profile: Athom smart plug v2.
{
    packages = {
        athom = "github://athom-tech/athom-configs/athom-smart-plug-v2.yaml";
        common = "!include common.yaml";
    };

    esp8266 = {
        board = "esp8285";
        early_pin_init = false;
    };
}
