{ lib, ... }: {
    options.technet = lib.mkOption {
        devices = {
            domain = "technet";
            "Ragnarok" = {
                folderName = "1-backup-server";
            };
            "Heimdall" = { };
            "Odin" = { };
            "Thor" = { };
        };
    };
}
