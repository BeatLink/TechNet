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

    environment.systemPackages = [
        (pkgs.callPackage "${inputs.mobile-nixos}/devices/pine64-pinephone/overlay/qfirehose" { })
    ];
}
