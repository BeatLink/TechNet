# Calibre Web Automated
#
# Used for eBook viewing and management.
#
# https://github.com/crocodilestick/Calibre-Web-Automated

{ inputs, pkgs, ... }:
{
    # Vigil's `calibre_web` plugin authenticates to /opds as this account to
    # confirm the DB layer actually serves a real book feed, not just that
    # the login page renders. Calibre-Web has no declarative user creation
    # (accounts live only in its own SQLite DB) — create a "vigil" user once
    # by hand under Admin > User Management with Guest/Download-only
    # permissions, then store its password here to match, the same
    # one-time-manual-step pattern as Traccar's vigil account (see
    # traccar.nix).
    sops.secrets.calibre_web_vigil_password = {
        sopsFile = "${inputs.self}/secrets/2-server/calibre-web.yaml";
        owner = "vigil-access";
    };

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
