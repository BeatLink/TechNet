# PinePhone Kernel Mirror ############################################################################################################################
#
# Unpacks megi's prebuilt kernel from its GitHub release asset and pushes it into Attic, so the fleet substitutes it from Heimdall.
#
# The flake used to publish the same cache over GitHub Pages, which answered HTTP 429 once more than a host or two pulled from it. Fetching the asset
# once here and re-serving it internally is what that rate limit was pushing towards. Building the kernel instead costs roughly 13 hours under binfmt
# -- see nix/5-phone/1-system/kernel.nix.
#

{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
let
    kernel = inputs.pinephone-kernel.packages.aarch64-linux.linux-pinephone-megi;

    # Discarding the context yields the paths as plain strings, so Heimdall's own closure does not gain an aarch64 kernel it would have to build.
    kernelPaths = lib.concatStringsSep " " (
        map (name: builtins.unsafeDiscardStringContext kernel.${name}.outPath) kernel.outputs
    );

    # The release tag carries the commit, so the locked input revision is the whole address; no API call and no "latest" to race against.
    releaseUrl = "https://github.com/BeatLink/PinePhoneKernel/releases/download/cache-${inputs.pinephone-kernel.rev}/binary-cache.tar.zst";

    cacheKey = "pinephone-kernel-1:Bh9JYKdNDBNwefy+ZrjHKjVUR453bPDXRMZ+kO9K33w=";
in
{
    systemd.services.pinephone-kernel-mirror = {
        description = "Mirror the PinePhone kernel into the Attic binary cache";
        after = [
            "network-online.target"
            "atticd.service"
        ];
        wants = [ "network-online.target" ];
        startAt = "daily";
        path = with pkgs; [
            attic-client
            curl
            gnutar
            nix
            zstd
        ];
        environment.XDG_CONFIG_HOME = config.technet.atticPush.configDir;
        serviceConfig = {
            Type = "oneshot";
            CacheDirectory = "pinephone-kernel-mirror";
        };
        script = ''
            if nix path-info ${kernelPaths} > /dev/null 2>&1; then
                echo "kernel already in the local store, skipping the download"
            else
                unpacked="$CACHE_DIRECTORY/binary-cache"
                rm -rf "$unpacked" && mkdir -p "$unpacked"
                curl -fsSL ${releaseUrl} | tar -x --zstd -C "$unpacked"
                nix copy --from "file://$unpacked" --extra-trusted-public-keys "${cacheKey}" ${kernelPaths}
                rm -rf "$unpacked"
            fi

            attic push technet ${kernelPaths}
        '';
    };

    # A missed run has to catch up: the paths change whenever the flake input moves, and the phone cannot be rebuilt until they are mirrored.
    systemd.timers.pinephone-kernel-mirror.timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "1h";
    };
}
