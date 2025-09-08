# Filesystem ########################################################################################################################################
#
# All TechNet Devices are provisioned with an encrypted ZFS filesystem and datasets, configured using disko.
#
# All TechNet devices follow the "Erase your Darlings" impermanent filesystem structure whereby the root filesystem is erased at every boot to prevent
# the buildup of state. To achieve this, every boot the system performs a rollback of the ZFS root filesystem to a clean snapshot. The root filesystem
# is then rebuilt from the contents of the Nix store and this configuration flake. All stateful data and configuration is either generated from this
# repo's flake, stored in /persistent or stored on the data drives
#
#
# Links: 
#   - https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
#   - https://discourse.nixos.org/t/impermanence-vs-systemd-initrd-w-tpm-unlocking/25167/3
#   - https://ethan.roo.ke/notes/nix-on-kimsufi/
#

{
    imports = [
        ./1-disko.nix
        ./2-mount.nix
        ./3-rollback.nix
        ./4-persistence.nix
        ./5-scrub.nix
        ./6-trim.nix
        ./7-disk-health.nix
        ./8-disk-space.nix
    ];
}
