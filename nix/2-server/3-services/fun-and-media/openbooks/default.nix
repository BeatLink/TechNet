# OpenBooks
#
# OpenBooks is an eBook downloader
#
{ pkgs, ... }:
{
    imports = [ ./module.nix ];

    # Downloads and state written while openbooks ran as other accounts are handed to its own; group and modes are folded in by
    # the ebooks-group script in syncthing.nix.
    system.activationScripts.openbooksChownToOpenbooks = {
        deps = [ "users" ];
        text = ''
            for dir in /Storage/Files/eBooks/OpenBooks /Storage/Services/OpenBooks; do
                if [ -d "$dir" ]; then
                    ${pkgs.findutils}/bin/find "$dir" \! -user openbooks \
                        -exec ${pkgs.coreutils}/bin/chown openbooks:ebooks {} + 2>/dev/null || true
                fi
            done
        '';
    };

    # websocat: Vigil's `http` monitor uses it to open one short-lived
    # WebSocket connection and confirm the IRC bridge is actually connected
    # (OpenBooks has no HTTP health endpoint of its own).
    environment.systemPackages = [ pkgs.websocat ];

    services.openbooks = {
        enable = true;
        # Its own account, sharing the download tree with Syncthing and calibre-web through the ebooks group (see syncthing.nix).
        group = "ebooks";
        dataDir = "/Storage/Services/OpenBooks";
        booksDir = "/Storage/Files/eBooks/OpenBooks";
        port = 9777;
        ircNick = "beatlink";
        persist = true;
        log = true;
    };
    systemd.services.openbooks.serviceConfig.UMask = "0002";

    nginx-vhosts."openbooks" = {
        domain = "openbooks.heimdall.technet";
        port = 9777;
    };
}
