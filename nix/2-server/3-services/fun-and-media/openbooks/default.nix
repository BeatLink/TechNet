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
