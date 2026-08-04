# Syncbus
#
# The bridge that makes phosh's Syncthing quick setting work. The plugin itself
# ships with phosh -- libphosh-plugin-syncthing-quick-setting.so is in the 0.56
# build from 1-system/14-phosh-bump.nix, and 1-system/6-display.nix lists it in
# sm/puri/phosh/plugins quick-settings -- but it is a pure D-Bus client. It
# talks to mobi.phosh.syncbus and to nothing else: no REST calls, no systemd
# calls of its own. With no such name on the session bus the panel shows its
# fallback, "Unable to connect to Syncbus", which is what it did here.
#
# Syncbus is a separate upstream project in the same group,
# gitlab.gnome.org/World/Phosh/syncbus, and is not in nixpkgs, so it is built
# here. It reads Syncthing's own config.xml for the GUI address and API key,
# then serves the panel over D-Bus and starts and stops syncthing.service
# through the user manager. That is why the quick setting can toggle Syncthing
# at all, and why the folder rows have live completion percentages.
#
# The config.xml it wants is the one under ~/.local/state/syncthing, which is
# the second of the three places it looks (STCONFDIR, then XDG_CONFIG_HOME,
# then XDG_STATE_HOME) and is where Syncthing 2 keeps it. That path is already
# persisted by 3-apps/technet/syncthing.nix, and already carries a <gui> block
# with address 127.0.0.1:8384 and an apikey, so nothing extra has to be
# declared for it.
#
{ pkgs, ... }:
let
    # Upstream drives cargo from meson, only to substitute two paths into the
    # service files and to build the workspace. buildRustPackage plus a
    # postInstall does the same thing without a second build system, and meson
    # is the layer that would otherwise need patching -- its custom_target
    # passes `&&` to cargo as an argument, which works under Debian's shell
    # wrapper and not in a Nix builder.
    #
    # -p server because the workspace also holds phosh-os-updater, a
    # sysupdate1 client for an OS this phone does not use, and a GTK demo.
    #
    # No TLS anywhere in the closure: reqwest is pulled in with
    # default-features = false, so this speaks plain HTTP to localhost only.
    syncbus = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "phosh-syncbus";
        version = "0.2.0";

        src = pkgs.fetchFromGitLab {
            domain = "gitlab.gnome.org";
            group = "World";
            owner = "Phosh";
            repo = "syncbus";
            tag = "v${finalAttrs.version}";
            hash = "sha256-R7fDO8aREj38dbqCn5gH3MQ+tIteEyR7lHqNM/wTEhQ=";
        };

        cargoHash = "sha256-d7CQyNprBHtANL6yWpA++ZmydtwSfkGgh18a+hz5YP8=";

        cargoBuildFlags = [
            "-p"
            "server"
        ];
        cargoTestFlags = [
            "-p"
            "server"
        ];

        # The same layout meson install would have produced. The binary is
        # libexec rather than bin because nothing launches it by hand -- both
        # the D-Bus service file and the systemd unit name it by full path.
        postInstall = ''
            mkdir -p $out/libexec $out/share/dbus-1/services \
                $out/share/dbus-1/interfaces $out/lib/systemd/user
            mv $out/bin/server $out/libexec/phosh-syncbus
            rmdir $out/bin

            substitute data/mobi.phosh.syncbus.service.in \
                $out/share/dbus-1/services/mobi.phosh.syncbus.service \
                --replace-fail '@LIBEXEC_DIR@' "$out/libexec" \
                --replace-fail '@EXE_NAME@' phosh-syncbus

            substitute data/phosh-syncbus.service.in \
                $out/lib/systemd/user/phosh-syncbus.service \
                --replace-fail '@LIBEXEC_DIR@' "$out/libexec" \
                --replace-fail '@EXE_NAME@' phosh-syncbus

            cp data/interfaces/*.xml $out/share/dbus-1/interfaces/
        '';

        meta = {
            description = "D-Bus server exposing Syncthing to phosh's quick setting";
            homepage = "https://gitlab.gnome.org/World/Phosh/syncbus";
            license = pkgs.lib.licenses.gpl3Plus;
            mainProgram = "phosh-syncbus";
            platforms = pkgs.lib.platforms.linux;
        };
    });
in
{
    # Three separate registrations, and they are not interchangeable.
    #
    # systemPackages puts share/dbus-1/services on XDG_DATA_DIRS, which is where
    # the session bus looks for activatable names. dbus.packages is the same
    # file by the supported route rather than by inheritance from the
    # environment. systemd.packages is what copies lib/systemd/user into
    # /etc/systemd/user -- without it the D-Bus service file's
    # SystemdService=phosh-syncbus.service names a unit the user manager has
    # never heard of, and activation fails with no obvious reason why.
    #
    # Nothing enables the unit. It is Type=dbus with BusName=mobi.phosh.syncbus,
    # and the plugin's proxy is created with G_DBUS_PROXY_FLAGS_NONE -- auto-start
    # on -- so phosh loading its plugins is what starts this, and there is no
    # value in having it running before then. Its own [Install] section says
    # WantedBy=mobi.phosh.Shell.target, which is left unlinked deliberately.
    #
    # The unit carries ConditionEnvironment=WAYLAND_DISPLAY. That is satisfied
    # here -- the phosh session imports WAYLAND_DISPLAY=wayland-0 into the user
    # manager -- but it is the thing to check first if the panel goes back to
    # showing the placeholder.
    environment.systemPackages = [ syncbus ];
    services.dbus.packages = [ syncbus ];
    systemd.packages = [ syncbus ];
}
