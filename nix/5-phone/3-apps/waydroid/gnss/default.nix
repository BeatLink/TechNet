# Waydroid GNSS ######################################################################################################################################
#
# A real GNSS HAL for the container, implemented on the host in Python over libgbinder, fed by geoclue. Android sees a satellite provider rather than
# a test provider, so fixes are not flagged as mock.
#

{ pkgs, lib, ... }:
let
    # Waydroid's own image has no GNSS HAL, so `gps` does not exist as a provider at all and only the mock ones can be driven.
    # waydroid/waydroid#2208 adds one as a host-side service, the same way the sensors and clipboard HALs already work.
    gnssHal = final: prev: {
        waydroid = prev.waydroid.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./patches/gnss-aidl-hal.patch ];

            # The patch ships `dummy` and `lomiri` providers, neither of which follows this phone; geoclue already has the fix.
            postPatch = (old.postPatch or "") + ''
                                cp ${./geoclue-provider.py} tools/services/gnss/providers/geoclue.py

                                substituteInPlace tools/services/gnss/providers/__init__.py \
                                    --replace-fail "from .dummy import DummyLocationProvider" \
                                        "from .dummy import DummyLocationProvider
                from .geoclue import GeoclueLocationProvider" \
                                    --replace-fail "'DummyLocationProvider'," "'DummyLocationProvider', 'GeoclueLocationProvider',"

                                substituteInPlace tools/services/gnss/gnss_manager.py \
                                    --replace-fail "from tools.services.gnss.providers import DummyLocationProvider, LomiriLocationProvider" \
                                        "from tools.services.gnss.providers import DummyLocationProvider, GeoclueLocationProvider, LomiriLocationProvider" \
                                    --replace-fail '    if provider_type == "dummy":' '    if provider_type == "geoclue":
                        logging.info("Gnss: Using geoclue location provider")
                        return GeoclueLocationProvider(cfg)

                    if provider_type == "dummy":'
            '';
        });

        # all-packages.nix builds this from the `waydroid` attribute above, but pin it here so the override cannot be missed.
        waydroid-nftables = final.waydroid.override { withNftables = true; };
    };

    # The image's own manifest declares no gnss interface, and the framework looks for one before it will talk to the HAL.
    gnssManifest = pkgs.writeText "gnss.xml" ''
        <manifest version="1.0" type="device">
            <hal format="aidl">
                <name>android.hardware.gnss</name>
                <version>2</version>
                <interface>
                    <name>IGnss</name>
                    <instance>default</instance>
                </interface>
            </hal>
        </manifest>
    '';
in
{
    nixpkgs.overlays = [ gnssHal ];

    # The provider asks for a client under this id, and geoclue hands out none to an id it does not know.
    services.geoclue2.appConfig.waydroid-gnss = {
        isAllowed = true;
        isSystem = false;
    };

    # Geoclue hands out no client at all until an agent is registered for the asking user -- every GetClient just times out, busctl included.
    # mkForce because the desktop module turns nixpkgs' demo agent off on the assumption the shell supplies one, and nothing here does.
    services.geoclue2.enableDemoAgent = lib.mkForce true;

    # `gnss_provider` lives in waydroid.cfg's [waydroid] section, which the props unit next door does not touch -- that one writes [properties].
    systemd.services.waydroid-gnss-provider = {
        description = "Select the geoclue GNSS provider in the Waydroid config";
        wantedBy = [ "multi-user.target" ];
        before = [ "waydroid-container.service" ];
        after = [ "var-lib-waydroid.mount" ];
        path = [
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
        ];
        unitConfig.ConditionPathExists = "/var/lib/waydroid/waydroid.cfg";
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = ''
            cfg=/var/lib/waydroid/waydroid.cfg

            if grep -q '^gnss_provider' "$cfg"; then
                sed -i 's|^gnss_provider.*|gnss_provider = geoclue|' "$cfg"
            else
                sed -i '/^\[waydroid\]/a gnss_provider = geoclue' "$cfg"
            fi

            # Copied, never symlinked: the overlay is read inside the container, where a /nix/store path does not exist and a dangling entry here
            # stops libvintf parsing the vendor manifest at all, which leaves the container restarting forever without ever finishing boot.
            install -D -m 0644 -o root -g root ${gnssManifest} \
                /var/lib/waydroid/overlay/vendor/etc/vintf/manifest/gnss.xml
        '';
    };

    # waydroid init writes the config itself, so the unit above is also fired the moment that file appears.
    systemd.paths.waydroid-gnss-provider = {
        description = "Set the GNSS provider once waydroid init has written its config";
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
            PathExists = "/var/lib/waydroid/waydroid.cfg";
            Unit = "waydroid-gnss-provider.service";
        };
    };
}
