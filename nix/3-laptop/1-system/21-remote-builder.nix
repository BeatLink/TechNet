# Remote builder
#
# Ragnarok is the only native aarch64 machine in the network, so Thor's closures
# are built there rather than under binfmt on this host. Emulation is correct but
# slow enough to matter: a kernel or anything Go-heavy takes hours under qemu and
# roughly an hour natively.
#
# nix-daemon runs as root, so the key it connects with has to be readable by
# root. Odin's own SSH host key is used rather than a new secret; the matching
# public half is authorised for beatlink on Ragnarok in 9-remote-builder.nix.
#
{
    nix = {
        distributedBuilds = true;

        buildMachines = [
            {
                hostName = "ragnarok.technet";
                sshUser = "beatlink";
                sshKey = "/persistent/etc/ssh/ssh_host_ed25519_key";
                systems = [ "aarch64-linux" ];
                protocol = "ssh-ng";
                maxJobs = 4;
                # Below the local machine's, so anything Odin can build natively
                # stays here and only foreign-architecture work is sent out.
                speedFactor = 1;
                supportedFeatures = [
                    "big-parallel"
                    "benchmark"
                ];
            }
        ];

        # Let the builder fetch from the binary cache itself rather than routing
        # every substitutable path through this machine and back over the tunnel.
        settings.builders-use-substitutes = true;
    };

    programs.ssh.extraConfig = ''
        Host ragnarok.technet
            StrictHostKeyChecking accept-new
    '';
}
