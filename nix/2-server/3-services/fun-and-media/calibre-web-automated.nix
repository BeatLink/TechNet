# Calibre Web Automated
#
# Used for eBook viewing and management.
#
# https://github.com/crocodilestick/Calibre-Web-Automated

{ inputs, pkgs, ... }:
{
    services.calibre-web-automated = {
        enable = true;
        package = inputs.calibre-web-automated.packages.${pkgs.system}.default;
        port = 8083;
        configDir = "/Storage/Services/Calibre-Web/config";
        libraryDir = "/Storage/Files/eBooks/Calibre/Library";
        ingestDir = "/Storage/Services/Calibre-Web/Uploads";
    };

    systemd.tmpfiles.rules = [
        "d /Storage/Services/Calibre-Web 0750 calibre-web calibre-web - -"
        "d /Storage/Services/Calibre-Web/config 0750 calibre-web calibre-web - -"
        "d /Storage/Services/Calibre-Web/Uploads 0750 calibre-web calibre-web - -"
        "d /Storage/Files/eBooks/Calibre/Library 0755 calibre-web calibre-web - -"
    ];

    users.users.calibre-web.extraGroups = [ "beatlink" ];

    nginx-vhosts.calibre-web = {
        domain = "calibre-web.heimdall.technet";
        port = 8083;
    };
}
