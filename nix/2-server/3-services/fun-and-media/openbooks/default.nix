# OpenBooks
#
# OpenBooks is an eBook downloader
#
{ pkgs, ... }:
{
    imports = [ ./module.nix ];

    # booksDir sits inside the eBooks Syncthing folder, which Syncthing walks as
    # beatlink. The module creates it 0750 openbooks:openbooks, so beatlink
    # could not even traverse it -- the folder logged "error while traversing
    # /Storage/Files/eBooks/OpenBooks: permission denied" and stopped syncing
    # with 2 pull errors.
    #
    # Put beatlink in the openbooks group and share the directory with that
    # group rather than loosening it to world or handing the tree to beatlink:
    # openbooks keeps ownership and still writes downloads as itself.
    users.users.beatlink.extraGroups = [ "openbooks" ];

    # The module creates booksDir 2770, but tmpfiles' `d` only applies its mode
    # when creating the directory -- this one already exists as 0750, so it
    # needs an explicit relabel. Scoped to the directory itself rather than a
    # recursive Z: everything below it is already group- and world-readable,
    # and a recursive 2770 would strip world-read from the existing log file and
    # mark it group-executable for no reason.
    systemd.tmpfiles.rules = [
        "z /Storage/Files/eBooks/OpenBooks 2770 openbooks openbooks - -"
    ];

    # websocat: Vigil's `openbooks` plugin uses it to open one short-lived
    # WebSocket connection and confirm the IRC bridge is actually connected
    # (OpenBooks has no HTTP health endpoint of its own).
    environment.systemPackages = [ pkgs.websocat ];

    services.openbooks = {
        enable = true;
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
