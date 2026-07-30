# Syncthing Mesh
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it
# also acts as a first line backup mechanism.
#
# The device IDs, the folder set and the tuning that has to agree on every peer live here rather than in each host's own syncthing module,
# because they are one shared contract: a folder id, a sync type or a set of ignore patterns that differs between two peers does not fail
# at build time, it fails at runtime as a folder that will not settle. Each host sets `syncthing-mesh.self` to its own device name and
# reads `syncthing-mesh.settings` into `services.syncthing.settings`, so the peer list and per-folder device list are derived rather than
# restated.
#
# Thor is the phone. Its Syncthing is configured on-device rather than through Nix, so it appears here only as a peer.
#
{
    config,
    lib,
    ...
}:

let
    cfg = config.syncthing-mesh;

    # Each peer is listed on the house LAN first and the TechNet VPN second, so
    # that two devices at home take the direct path and fall back to the tunnel
    # only when one of them is away.
    #
    # The .lan names do not all resolve yet. Pi-hole serves `lan` as a local
    # domain but its static hosts list only holds .technet entries, so today
    # heimdall.lan answers with the VPN address (expand-hosts appending the
    # domain to heimdall.technet) while odin.lan and thorx.lan do not answer at
    # all. Syncthing treats an address it cannot resolve as one dead entry in
    # the list and keeps using the rest, so these are declared ahead of the DNS
    # records rather than after them; giving each host an A record on
    # 192.168.0.0/24 is what turns them into the direct path. Thor is a DHCP
    # phone and needs a fixed lease before its name can be pointed anywhere.
    devices = {
        Heimdall = {
            id = "Q6AIAK4-4PFLB3Z-73QF54Y-EKQ2LC5-5FSVFRZ-RBGWFDI-KZQI45E-JBXXTQY";
            addresses = [
                "tcp://heimdall.lan:22000"
                "tcp://heimdall.technet:22000"
            ];
        };
        Odin = {
            id = "CSIQ7OW-6MP3FSB-OBDABEA-S53TWYT-N2EFGT6-4FMUV7R-HMXLOF5-GLIW7AD";
            addresses = [
                "tcp://odin.lan:22000"
                "tcp://odin.technet:22000"
            ];
        };
        Thor = {
            id = "AGVZ3DQ-LX5CBXY-G6NKD4E-HOW7QNG-KAGSVOY-KRBUABG-BCDNEPU-SHJF4Q4";
            addresses = [
                "tcp://thorx.lan:22000"
                "tcp://thorx.technet:22000"
            ];
        };
    };

    allPeers = lib.attrNames devices;
    folders = {
        Documents = { };
        Downloads = {
            ignorePatterns = [
                "(?d)*.!qB"
                "(?d)*.parts"
                "(?d)/Torrents/Downloading"
            ];
        };
        eBooks = {
            ignorePatterns = [ "/OpenBooks/logs" ];
        };
        Music = { };
        Pictures = { };
        Projects = {
            devices = [
                "Heimdall"
                "Odin"
            ];
        };
        Sounds = { };
        Videos = { };
    };
    folderIds = {
        Documents = "hz0k1-egjw9";
        Downloads = "unmbe-b2iab";
        eBooks = "kj0id-3vcea";
        Music = "8g86n-1309l";
        Pictures = "ta09s-b2u0y";
        Projects = "xjtvv-cyqwv";
        Sounds = "kae2q-5740v";
        Videos = "4kqye-6dosm";
    };
in
{
    options.syncthing-mesh = {
        self = lib.mkOption {
            type = lib.types.enum allPeers;
            description = "This host's device name within the mesh.";
        };

        folderOptions = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = ''
                Per-folder settings merged under every folder on this host, for
                tuning that is host-local rather than part of the shared
                contract (scan intervals, worker pool sizes).
            '';
        };

        settings = lib.mkOption {
            type = lib.types.attrs;
            readOnly = true;
            description = "Syncthing settings for this host, to read into services.syncthing.settings.";
        };
    };

    config.syncthing-mesh.settings = {
        options = {
            globalAnnounceEnabled = false;
            relaysEnabled = false;
            natEnabled = false;
            urAccepted = -1;
        };

        devices = lib.mapAttrs (_: device: {
            inherit (device) id addresses;
            numConnections = 8;
        }) (lib.filterAttrs (name: _: name != cfg.self) devices);

        folders = lib.mapAttrs' (
            name: folder:
            lib.nameValuePair "/Storage/Files/${name}" (
                cfg.folderOptions
                // {
                    label = name;
                    id = folderIds.${name};
                    type = "sendreceive";
                    devices = lib.subtractLists [ cfg.self ] (folder.devices or allPeers);
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                    ignorePerms = false;
                }
                // (removeAttrs folder [ "devices" ])
            )
        ) folders;
    };
}
