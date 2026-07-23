#  ESPHome
#
#  ESPHome builds and flashes the firmware for the ESP8266/ESP8285 devices around
#  the house (bulbs, sockets, presence sensors and the bedroom IR blaster).
#
#  Device configs are declarative: each device and hardware profile is a `.nix`
#  file under `devices/` and `templates/`, rendered to YAML at build time and
#  bind-mounted read-only into the dashboard's state directory. Nix is the
#  single source of truth, so the dashboard's *editor* can no longer save
#  changes -- edit the `.nix` files and rebuild instead. Compiling, flashing
#  and OTA all still work from the dashboard as before.
#
#  Bind mounts, not symlinks: ESPHome's dashboard resolves each config path
#  and rejects it if that resolves outside the state directory (a path-
#  traversal guard). A symlink into `/nix/store` fails that check, so every
#  device silently 500s when opened. Bind-mounting a real file over an empty
#  placeholder keeps the path itself inside the state directory while the
#  content still comes from the store.
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
    # Hardware profiles are `!include`-only building blocks, not standalone
    # devices -- dot-prefixing their filenames hides them from the dashboard's
    # listing (it skips dotfiles) while leaving them resolvable as same-directory
    # `!include`s. Without this, the dashboard lets you compile/flash a profile
    # directly, which registers under the upstream package's default hostname
    # instead of any of the real devices' names and can never be reached by OTA.
    dotPrefix = lib.mapAttrs' (name: value: lib.nameValuePair ".${name}" value);
    configFiles = dotPrefix (esphomeLib.renderDir ./templates) // esphomeLib.renderDir ./devices;

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
    # Rendered YAML lives in the store and is bind-mounted onto an empty
    # placeholder file in the state directory, so the config's path stays
    # inside the state directory while its content stays Nix-owned. Files are
    # mounted individually so the build caches alongside them stay writable.
    systemd.tmpfiles.rules =
        lib.mapAttrsToList (name: _: "f ${stateDir}/${name} 0444 esphome esphome") configFiles
        ++ [
            "L+ ${stateDir}/secrets.yaml - - - - ${config.sops.templates."esphome-secrets.yaml".path}"
        ];

    systemd.mounts = lib.mapAttrsToList (name: drv: {
        what = "${drv}";
        where = "${stateDir}/${name}";
        type = "none";
        options = "bind,ro";
        requires = [ "var-lib-esphome.mount" ];
        after = [ "var-lib-esphome.mount" ];
        wantedBy = [ "esphome.service" ];
        before = [ "esphome.service" ];
    }) configFiles;

    # Setup Nginx Virtual Host and Pi-Hole -----------------------------------------------------------------------------------------------------
    nginx-vhosts.esphome = {
        domain = "esphome.heimdall.technet";
        port = 6052;
    };
}
