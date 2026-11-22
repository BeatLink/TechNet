# Modem
#
# The EG25-G is driven by eg25-manager. QFirehose flashes its firmware and is
# packaged only by mobile-nixos, so it is taken from that input directly.
#
{
    inputs,
    lib,
    pkgs,
    ...
}:
{
    services.eg25-manager.enable = lib.mkDefault true;

    # A missing SIM leaves the modem running with its SIM-dependent interfaces off, instead of failed and reprobed on every resume
    networking.modemmanager.package = pkgs.modemmanager.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/modemmanager-sim-optional.patch ];
    });

    nixpkgs.overlays = [
        (final: _prev: {
            pinephone-qfirehose =
                (final.callPackage "${inputs.mobile-nixos}/devices/pine64-pinephone/overlay/qfirehose" { })
                .overrideAttrs
                    (old: {
                        # universe2.us no longer answers, and curl retries it for minutes; the Wayback Machine holds the same tarball, so the hash and store path are unchanged
                        src = final.fetchurl {
                            urls = [
                                "https://web.archive.org/web/20201018192757/https://universe2.us/collector/qfirehose_good.tar.zst"
                            ]
                            ++ old.src.urls;
                            inherit (old.src) outputHash outputHashAlgo;
                        };
                    });
        })
    ];

    environment.systemPackages = [ pkgs.pinephone-qfirehose ];
}
