#  ESPHome
#
#  ESPHome builds and flashes the firmware for the ESP8266/ESP8285 devices around
#  the house (bulbs, sockets, presence sensors and the bedroom IR blaster).
#
#  Device configs are declarative: each device and hardware profile is a `.nix`
#  file under `devices/` and `templates/`, rendered to YAML at build time and
#  symlinked read-only into the dashboard's state directory. Nix is the single
#  source of truth, so the dashboard's *editor* can no longer save changes --
#  edit the `.nix` files and rebuild instead. Compiling, flashing and OTA all
#  still work from the dashboard as before.
#
#  The build caches (`.esphome/`, `.platformio/`) and `secrets.yaml` deliberately
#  stay mutable; only the config files themselves are Nix-owned.

{
    inputs,
    config,
    pkgs,
    lib,
    ...
}:
let
    esphomeLib = import ./lib.nix { inherit pkgs lib; };

    stateDir = "/var/lib/esphome";

    # `{ "<name>.yaml" = <derivation>; }` for every device and hardware profile.
    configFiles = esphomeLib.renderDir ./templates // esphomeLib.renderDir ./devices;

    deviceSecretsFile = "${inputs.self}/secrets/2-server/esphome-secrets.yaml";

    # The `!secret` names the device configs refer to, read off the encrypted
    # file itself so adding a secret needs no change here. Only the top-level
    # keys are wanted -- `sops:` is the encryption metadata, not a secret.
    deviceSecretKeys = lib.filter (k: k != "sops") (
        lib.concatMap (
            line: let m = builtins.match "^([a-zA-Z0-9_-]+):.*" line; in lib.optionals (m != null) m
        ) (lib.splitString "\n" (builtins.readFile deviceSecretsFile))
    );
in
{
    # Enable the service -----------------------------------------------------------------------------------------------------------------------
    services.esphome = {
        enable = true;
        port = 6052;
        address = "localhost";
        usePing = true;
    };

    environment.persistence."/Storage/Services/ESPHome".directories = [ stateDir ];

    # Configure authentiation ------------------------------------------------------------------------------------------------------------------
    # The dashboard's own HTTP credentials, plus the per-device secrets below.
    sops.secrets = {
        esphome_env.sopsFile = "${inputs.self}/secrets/2-server/esphome.yaml";
    }
    // lib.genAttrs deviceSecretKeys (_: {
        sopsFile = deviceSecretsFile;
        owner = "esphome";
        group = "esphome";
    });

    systemd.services.esphome.serviceConfig = {
        EnvironmentFile = config.sops.secrets.esphome_env.path;
    };

    # Device secrets ---------------------------------------------------------------------------------------------------------------------------
    # Each key is decrypted individually and reassembled into the `secrets.yaml`
    # that the `!secret` references in the device configs resolve against.
    sops.templates."esphome-secrets.yaml" = {
        owner = "esphome";
        group = "esphome";
        mode = "0400";
        content = lib.concatMapStringsSep "\n" (
            key: "${key}: ${config.sops.placeholder.${key}}"
        ) deviceSecretKeys;
    };

    # Device configurations --------------------------------------------------------------------------------------------------------------------
    # Rendered YAML lives in the store and is linked into the state directory.
    # Files are linked individually so the build caches alongside them stay
    # writable.
    systemd.tmpfiles.rules =
        lib.mapAttrsToList (name: drv: "L+ ${stateDir}/${name} - - - - ${drv}") configFiles
        ++ [
            "L+ ${stateDir}/secrets.yaml - - - - ${config.sops.templates."esphome-secrets.yaml".path}"
        ];

    # Setup Nginx Virtual Host and Pi-Hole -----------------------------------------------------------------------------------------------------
    nginx-vhosts.esphome = {
        domain = "esphome.heimdall.technet";
        port = 6052;
    };
}
