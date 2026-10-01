# Jackett
#
# Jackett translates queries across many torrent trackers into a single API.
# qbittorrent.nix installs a search plugin that lets qBittorrent's own
# Search tab query this directly; a *arr app (Sonarr/Radarr) would be the
# other common way to consume it, but isn't set up here.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    # Definition overrides for indexers whose packaged definitions predate a domain or layout change; bump commit and hashes together, and drop an entry once a package upgrade catches up.
    definitionCommit = "d0d2362905ee577482697359a20a7932d52b9458";
    definitionOverrides = {
        "52bt" = "191lyls18cyzs0hrbd1kfmxbfqys9596g1m0hgm8ljxm3yjq207x";
        "linuxtracker" = "11gi2r26xbkwkzpq42hqpi4nxcf0cmx3mmqca9kfppia2cjj7sli";
        "torrent9" = "0s86qk42hcx5w6jcaz0x4yydifby7cdzmhc9yyhhi24f4i8ar4sk";
    };
    definitionFile =
        name: sha256:
        pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/Jackett/Jackett/${definitionCommit}/src/Jackett.Common/Definitions/${name}.yml";
            inherit sha256;
        };
in
{
    services.jackett = {
        enable = true;
        dataDir = "/Storage/Services/Jackett";
        port = 9117;
    };

    systemd.services.jackett.serviceConfig.ExecStart = lib.mkForce (
        "${config.services.jackett.package}/bin/Jackett --NoUpdates --ListenPrivate"
        + " --Port ${toString config.services.jackett.port}"
        + " --DataFolder '${config.services.jackett.dataDir}'"
    );

    # Jackett resolves its custom cardigann/definitions/ dir against the process cwd, so without this it looks in / and loads no overrides
    systemd.services.jackett.serviceConfig.WorkingDirectory = config.services.jackett.dataDir;

    # Installs the pinned definition overrides where the WorkingDirectory setting above makes Jackett look for them.
    systemd.services.jackett.serviceConfig.ExecStartPre = [
        (lib.getExe (
            pkgs.writeShellApplication {
                name = "jackett-install-definition-overrides";
                runtimeInputs = [ pkgs.coreutils ];
                text = lib.concatMapStringsSep "\n" (name: ''
                    install -Dm644 ${definitionFile name definitionOverrides.${name}} \
                        '${config.services.jackett.dataDir}/cardigann/definitions/${name}.yml'
                '') (lib.attrNames definitionOverrides);
            }
        ))
    ];
    nginx-vhosts.jackett = {
        domain = "jackett.heimdall.technet";
        port = 9117;
    };
}
