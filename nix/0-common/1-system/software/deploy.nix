# Deployment Arguments ###############################################################################################################################
#
# One definition of how each host is deployed, read by Heimdall's monitors and by every host's sudo rules so the two cannot drift apart.
#
# sudoers matches a command argument for argument, and the arguments live in Heimdall's config while the rule lives in the target's, so neither can
# read the other. A plain attrset both import is what keeps them identical.
#
rec {
    # The lock belongs to the flake's own commit, and -L puts the build log in the job output.
    baseArgs = [
        "--no-write-lock-file"
        "-L"
    ];

    # Heimdall builds the fleet into Attic and these hosts substitute from it, so a path the cache is missing would otherwise be compiled on the host.
    substituteOnlyArgs = baseArgs ++ [
        "--max-jobs"
        "0"
    ];

    # Per-host, defaulting to building locally. The plugin appends --refresh itself for a mutable flake reference.
    forHost =
        host:
        if
            builtins.elem host [
                "Thor"
                "Ragnarok"
            ]
        then
            substituteOnlyArgs
        else
            baseArgs;
}
