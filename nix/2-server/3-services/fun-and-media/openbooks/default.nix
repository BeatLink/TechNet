# OpenBooks
#
# OpenBooks is an eBook downloader
#
{ pkgs, ... }:
{
    imports = [ ./module.nix ];

    # Downloads created while openbooks ran under its own account are still owned
    # by a uid that no longer has a name, which leaves Syncthing unable to chmod
    # them now that the eBooks folder syncs permission bits. One-time migration
    # of the openbooks tree only -- the rest of eBooks is already beatlink's.
    #
    # logs/ is pruned: it belongs to vigil, which writes OpenBooks probe logs
    # there as itself. It happens to sit inside the synced tree, but handing it
    # to beatlink would leave vigil unable to write its own logs.
    system.activationScripts.openbooksChownToBeatlink = ''
        for dir in /Storage/Files/eBooks/OpenBooks /Storage/Services/OpenBooks; do
            if [ -d "$dir" ]; then
                ${pkgs.findutils}/bin/find "$dir" \
                    -path /Storage/Files/eBooks/OpenBooks/logs -prune -o \
                    \! -user beatlink \
                    -exec ${pkgs.coreutils}/bin/chown beatlink:beatlink {} + 2>/dev/null || true
            fi
        done
    '';

    # The module creates booksDir 2770, but tmpfiles' `d` only applies its mode
    # when creating the directory -- this one already exists, so it needs an
    # explicit relabel to pick up the new ownership. Scoped to the directory
    # itself rather than a recursive Z: everything below it is already group- and
    # world-readable, and a recursive 2770 would strip world-read from the
    # existing log file and mark it group-executable for no reason.
    systemd.tmpfiles.settings."OpenBooks-Relabel"."/Storage/Files/eBooks/OpenBooks".z = {
        user = "beatlink";
        group = "beatlink";
        mode = "2770";
    };

    # websocat: Vigil's `http` monitor uses it to open one short-lived
    # WebSocket connection and confirm the IRC bridge is actually connected
    # (OpenBooks has no HTTP health endpoint of its own).
    environment.systemPackages = [ pkgs.websocat ];

    services.openbooks = {
        enable = true;
        # Runs as beatlink so downloads land already owned by the account
        # Syncthing runs as. The eBooks folder syncs permission bits and chmod is
        # owner-restricted, so a separate openbooks account would stall it
        # regardless of group memberships.
        user = "beatlink";
        group = "beatlink";
        dataDir = "/Storage/Services/OpenBooks";
        booksDir = "/Storage/Files/eBooks/OpenBooks";
        port = 9777;
        ircNick = "beatlink";
        persist = true;
        log = true;
    };
    nginx-vhosts."openbooks" = {
        domain = "openbooks.heimdall.technet";
        port = 9777;
    };
}
