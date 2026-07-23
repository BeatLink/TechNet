# OpenBooks
#
# OpenBooks is an eBook downloader
#
{ pkgs, ... }:
{
    imports = [ ./module.nix ];

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
