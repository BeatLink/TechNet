# ThorX — Android phone

| | |
| --- | --- |
| Device | Samsung Galaxy A05 (SM-A055M), Android 15 |
| Address | `thorx.technet`, `10.100.100.5` over WireGuard |
| Configured | On the device; nothing here is built by Nix |

ThorX's Syncthing is set up on the phone itself; see
[`syncthing.nix`](../nix/0-common/3-services/syncthing.nix).

## adb from Odin

Odin reaches ThorX over adb on a fixed port, with no pairing after the first time:

```sh
adb connect 10.100.100.5:<port>
```

The port is the one set in ADB Auto Enable on the phone. It is kept out of this
public repo; the app's status screen shows it.

### How it works

- **Odin** has `adb` from
  [`android-debug-bridge.nix`](../nix/3-laptop/4-apps/tools/android-debug-bridge.nix).
  Its key lives in `~/.android`, persisted under
  `/Storage/Apps/Tools/Android-Debug-Bridge`, and ThorX trusts that key, so the
  pairing survives reboots on both ends. The key is the only secret; it never
  goes in the repo or in sops.
- **ThorX** runs
  [ADB Auto Enable](https://github.com/mouldybread/adb-auto-enable)
  (`com.tpn.adbautoenable`). At every boot it switches wireless debugging on,
  finds the random port Android gives it, and moves adb to the fixed port.

Android picks a new random wireless debugging port each time it is switched on,
and nixpkgs' `adb` cannot discover it, since it is built without mDNS. The app's
fixed port is what makes `adb connect` work without looking the port up.

### Setting it up again

After a factory reset, or for a new Odin key:

1. On ThorX, open Developer options, then **Wireless debugging**, and turn it on.
2. Pair Odin: tap **Pair device with pairing code**, then on Odin run
   `adb pair 10.100.100.5:<pairing port> <code>`.
3. Connect once on the random port shown on the Wireless debugging screen:
   `adb connect 10.100.100.5:<port>`. If the screen is out of reach,
   `nix run nixpkgs#nmap -- -Pn -p 30000-50000 --open 10.100.100.5` finds it.
4. Install the app's APK from its GitHub releases with `adb install`, and open it.
5. Pair the app: start a second **Pair device with pairing code** and enter that
   code and port in the app. The app pairs with the phone's own adb over loopback.
6. Grant it the settings permission from Odin:
   `adb shell pm grant com.tpn.adbautoenable android.permission.WRITE_SECURE_SETTINGS`.
   The app tries to grant this to itself, but that fails while the VPN is up
   (below).
7. Set the target port in the app, then tap **Test** to run its boot routine. Its
   log should end with `Successfully configured ADB on port <port>!`.
8. Turn the app's web server off. Its control page on port 9093 has no password.

### Hazards

- **The VPN hides the phone from the app.** WireGuard is ThorX's active network,
  so the app takes `10.100.100.5` as its own address. The phone advertises adb
  only on its Wi-Fi address, so the app skips that advertisement. The **Discover**
  button then fails, and so does the app's self-grant of the permission. The
  boot routine still works, because it falls back to scanning every port.
- **The fixed port is open on every network ThorX joins**, including public Wi-Fi,
  and the connection is not encrypted. A computer still needs its key approved
  on the phone before adb lets it in.
- **The app holds adb access to the phone itself.** That is how it switches the
  port, so it can run shell commands on ThorX.
