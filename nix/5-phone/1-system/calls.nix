# GNOME Calls
#
# Builds the dialer without its test suite, which cannot run where this host's closure is built.
#
{ ... }:
{
    nixpkgs.overlays = [
        (_final: prev: {
            # The tests drive the UI under bwrap, and a nested user namespace is one thing qemu-user cannot emulate, so an aarch64 build on Odin dies there.
            calls = prev.calls.overrideAttrs (_: {
                doCheck = false;
            });
        })
    ];
}
