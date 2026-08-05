# Desktop Configuration Module Imports
#
# Shared by the hosts that have a screen and a user in front of them -- Odin and
# Thor. Each imports it explicitly from its own default.nix.
#
# Deliberately NOT imported by 0-common/default.nix, which Heimdall and Ragnarok
# also pull in: neither has a display, and neither wants a browser or a file
# manager in its closure. Living under 0-common keeps it next to the rest of the
# shared configuration; not being auto-imported is what keeps it off the servers.
#
# Anything here has to work on both a laptop and a phone. Where they genuinely
# differ, the module exposes an option and each host fills it in -- the file
# manager is the clearest case: Odin runs Nemo and Thor runs Nautilus, so only
# the bookmark list they both read is shared, in 4-apps/system/file-manager.nix.
#

{
    imports = [
        ./1-system
        ./4-apps
    ];
}
