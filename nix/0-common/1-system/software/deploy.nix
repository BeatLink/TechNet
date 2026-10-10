# Deployment Arguments ###############################################################################################################################
#
# One definition of how each host is deployed, read by Heimdall's monitors and sudo rules and by every target's deploy account, so they cannot drift.
#
# sudoers matches a command argument for argument, and the arguments live in Heimdall's config while the account lives in the target's, so neither
# can read the other. A plain attrset both import is what keeps them identical.
#
rec {
    # The lock belongs to the flake's own commit, and -L puts the build log in the job output.
    baseArgs = [
        "--no-write-lock-file"
        "-L"
    ];

    # Heimdall builds these hosts and activates them over SSH as their `deploy` account; the target fetches what it can from the caches itself.
    remoteArgs = baseArgs ++ [
        "--sudo"
        "--use-substitutes"
    ];

    # Hosts Heimdall deploys over SSH, with each one's login, its key's public half and anything to run on it once the switch is done.
    remote = {
        Odin = {
            target = "deploy@odin.technet";
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyksZY+vqtBMqisWUItl+u546G/yKAMR2ZL9JT4yFmp heimdall-deploy@odin";
            postSwitch = null;
        };
        Thor = {
            target = "deploy@thor.technet";
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP/jiNh353L4puqxFr2Vv9qnt8ilMZL4YSEp0rJsIob heimdall-deploy@thor";
            postSwitch = "systemctl is-active -q phosh.service || sudo /run/current-system/sw/bin/systemctl restart phosh.service"; # A switch that touches phosh stops it and leaves the screen dark
        };
        Ragnarok = {
            target = "deploy@ragnarok.technet";
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMN95bs1iMrHR16PfWSBi9khxqulp0dAvpMi01QC2vCX heimdall-deploy@ragnarok";
            postSwitch = null;
        };
    };

    # The addresses Heimdall reaches the targets from: WireGuard, and the LAN for a target resolved there.
    heimdallAddresses = [
        "10.100.100.1"
        "192.168.0.2"
    ];

    forHost = host: if remote ? ${host} then remoteArgs else baseArgs;
}
