# Home automation

Home Assistant, ESPHome, Frigate and Mosquitto run on Heimdall, under
[`home-automation`](../nix/2-server/3-services/home-automation).

## Home Assistant

- ESPHome config entries store each device's host in `.storage/core.config_entries`, and with mDNS off on every
  device HA never learns a new address. Before renaming or re-addressing devices, rewrite those hosts with jq while
  `home-assistant` is stopped, then count HA's connections to port 6053 with `ss`.
- Deleting a config entry imports its integration first, so an entry whose module is missing returns a 500 and
  stays. Stop HA, copy `core.config_entries`, `core.entity_registry`, `core.device_registry` and
  `repairs.issue_registry` aside right after the stop, filter on `config_entry_id`, write back in place, and start
  HA again. Dry-run the filters on copies.
- A switch that changes only `configuration.yaml` says "would reload" but restarts HA.
- On an ESPHome reconnect, entities come back one by one, so a `wait_template` can see a sibling still
  `unavailable`. Athom "Uptime" is text, so `numeric_state` on it never fires. Entity ids differ between old and
  re-adopted devices; read `.storage/core.entity_registry` before writing a package.
- [`fan-speed-buttons.js`](../nix/2-server/3-services/home-automation/home-assistant/fan-speed-buttons.js) relies
  on frontend internals: the elements `ha-state-control-fan-speed` and `hui-fan-speed-card-feature`,
  `LitElement.prototype.html`, and `stateObj`/`context` surviving minification. After a `home-assistant-frontend`
  bump, grep the new wheel's `hass_frontend/frontend_latest/*.js` for each of those.

## ESPHome

- `esphome config` checks the schema only; C++ errors in lambdas show up only from `esphome compile`. To check a
  device off-host, render it with `lib.nix`'s `renderConfig`, copy it and the rendered templates into a scratch
  directory with `cp --no-preserve=mode`, add a dummy `secrets.yaml` with a real 32-byte base64 API key, and run
  `nix run nixpkgs#esphome -- compile <device>.yaml`.
- Flash from Heimdall as the `esphome` user with the CLI the Device Builder calls, since the service's PATH has no
  `esphome`. Never pipe a flash through `tail`.
- OTA "not enough space" means the running firmware uses the 1 MB linker layout. Every Athom board here is a 2 MB
  ESP8285: flash `minimal-image.yaml` first, then the real config to the device's IP.

## Frigate

- Camera toggles set over MQTT or the UI are saved to `.runtime_state.json` in `/run/frigate`, which a restart
  wipes. A camera that comes up off is almost always a retained `frigate/<cam>/enabled/set OFF` on the broker:
  find it with `mosquitto_sub -t 'frigate/<cam>/#' -v -W 3` and clear it with `mosquitto_pub -t … -n -r`.
- The USB webcam can wedge into delivering only corrupt frames. Heimdall's root hub has no power switching, so no
  software unbind or port disable resets it; only a physical replug does.
