{
    programs.ssh = {
        knownHosts = {
            "odin" = {
                publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p";
                hostNames = [
                    "localhost"
                ];
            };
        };
    };
}
