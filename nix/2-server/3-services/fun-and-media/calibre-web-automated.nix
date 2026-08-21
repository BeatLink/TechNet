# Calibre Web Automated
#
# Used for eBook viewing and management.
#
# https://github.com/crocodilestick/Calibre-Web-Automated

{ config, inputs, pkgs, ... }:
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
        sopsFile = "${config.technet.secrets.path}/calibre-web.yaml";
        group = "vigil-monitor";                                        # Read by whichever Vigil transport runs the `cat` — the agent today, vigil-access as fallback
        mode = "0440";
    };

    services.calibre-web-automated = {
        enable = true;
        package = inputs.calibre-web-automated.packages.${pkgs.stdenv.hostPlatform.system}.default;
        port = 8083;
        configDir = "/Storage/Services/Calibre-Web/config";
        libraryDir = "/Storage/Files/eBooks/Calibre/Library";
        ingestDir = "/Storage/Services/Calibre-Web/Uploads";
    };

    systemd.tmpfiles.settings."Calibre-Web" = {
        "/Storage/Services/Calibre-Web".d = {
            user = "calibre-web";
            group = "calibre-web";
            mode = "0750";
        };
        "/Storage/Services/Calibre-Web/config".d = {
            user = "calibre-web";
            group = "calibre-web";
            mode = "0750";
        };
        "/Storage/Services/Calibre-Web/Uploads".d = {
            user = "calibre-web";
            group = "calibre-web";
            mode = "0750";
        };
        "/Storage/Files/eBooks/Calibre/Library".d = {
            user = "calibre-web";
            group = "calibre-web";
            mode = "0755";
        };
    };

    users.users.calibre-web.extraGroups = [ "beatlink" ];

    nginx-vhosts.calibre-web = {
        domain = "calibre-web.heimdall.technet";
        port = 8083;
    };
}
