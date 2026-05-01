# OpenBooks
#
# OpenBooks is an eBook downloader
#
{
    imports = [ ./module.nix ];
    services.openbooks = {
        enable = true;
        dataDir = "/Storage/Services/OpenBooks";
        booksDir = "/Storage/Files/eBooks/OpenBooks";
        host = "127.0.0.1";
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
