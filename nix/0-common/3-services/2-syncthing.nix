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
# ThorX is the Android phone, at thorx.technet / 10.100.100.5. Its Syncthing is configured on the device rather than through Nix, so it
# appears here only as a peer. It used to be called Thor, which collided with the PinePhone -- a NixOS host whose networking.hostName is
# also Thor, at thor.technet / 10.100.100.4. pi-hole's device list has always distinguished the two; the mesh had not.
#
{
    config,
    lib,
    ...
}:

let
    cfg = config.syncthing-mesh;
    devices = {
        Heimdall = {
            id = "Q6AIAK4-4PFLB3Z-73QF54Y-EKQ2LC5-5FSVFRZ-RBGWFDI-KZQI45E-JBXXTQY";
            addresses = [
                "tcp://heimdall.lan:22000"
                "tcp://heimdall.technet:22000"
            ];
        };
        Ragnarok = {
            id = "FSC6NQO-AS3VEAV-7TDTECF-MHBLG4P-A2SGTKM-E4ZTEBH-5TLLFR2-DMWGNQK";
            addresses = [
                "tcp://ragnarok.lan:22000"
                "tcp://ragnarok.technet:22000"
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
            id = "DGCLOUO-G4JS2TA-Q65LAHH-2F53VKG-SCFK5UQ-RK7HYQH-3XUEDPV-E4OA7QV";
            addresses = [
                "tcp://thor.lan:22000"
                "tcp://thor.technet:22000"
            ];
        };
        ThorX = {
            id = "AGVZ3DQ-LX5CBXY-G6NKD4E-HOW7QNG-KAGSVOY-KRBUABG-BCDNEPU-SHJF4Q4";
            addresses = [
                "tcp://thorx.lan:22000"
                "tcp://thorx.technet:22000"
            ];
        };
    };

    allPeers = lib.attrNames devices;
    exceptThor = lib.subtractLists [ "Thor" ] allPeers;

    # Merged into every folder's patterns; (?d) lets peers delete what they already hold
    commonIgnorePatterns = [
        "(?d)node_modules"
        "(?d)/**/target/debug"
        "(?d)/**/target/release"
        "(?d)__pycache__"
        "(?d).venv"
        "(?d)*.pyc"
    ];

    folders = {
        Documents = { };
        Downloads = {
            devices = exceptThor;
            ignorePatterns = [
                "(?d)*.!qB"
                "(?d)*.parts"
                "(?d)/Torrents/Downloading"
            ];
        };
        eBooks = {
            ignorePatterns = [ "/OpenBooks/logs" ];
        };
        Music = {
            ignorePatterns = [
                ".thumbnails"
                ".database_uuid"
                ".nomedia"
            ];
        };
        Pictures = { };
        Projects = {
            devices = [
                "Heimdall"
                "Odin"
            ];
        };
        Sounds = {
            devices = exceptThor;
        };
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
                # Three layers, and the order is the point. Defaults a host may
                # replace come first; folderOptions second, so a host can; the
                # shared contract last, because a folder id or device list that
                # differs between two peers does not fail at build time, it
                # fails at runtime as a folder that will not settle.
                #
                # versioning is a default rather than contract. It used to sit
                # in the contract layer, which silently discarded any host that
                # set it -- Ragnarok asked for staggered and got trashcan with
                # no error anywhere.
                {
                    versioning = {
                        type = "trashcan";
                        params.cleanoutDays = "30";
                    };
                }
                // cfg.folderOptions
                // {
                    label = name;
                    id = folderIds.${name};
                    type = "sendreceive";
                    devices = lib.subtractLists [ cfg.self ] (folder.devices or allPeers);
                    ignorePerms = false;
                }
                // (removeAttrs folder [
                    "devices"
                    "ignorePatterns"
                ])
                # Concatenated rather than merged: `//` would let a folder's own
                # patterns replace the shared list instead of adding to it.
                // {
                    ignorePatterns = commonIgnorePatterns ++ (folder.ignorePatterns or [ ]);
                }
            )
            # Load-bearing: without it a host configures folders it is not a member of and scans them for nothing.
        ) (lib.filterAttrs (_: folder: builtins.elem cfg.self (folder.devices or allPeers)) folders);
    };
}
