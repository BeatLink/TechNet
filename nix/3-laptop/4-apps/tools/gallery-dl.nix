# Gallery-DL #########################################################################################################################################
#
# Downloads galleries, and records the page each one came from so BlockURL can hide it from the browser once it has been downloaded.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    apiUrl = "https://blockurl.heimdall.technet";
    apiKeyFile = config.sops.secrets.blockurl_api_key.path;

    stateDir = "/Storage/Apps/Tools/Gallery-DL/blockurl"; # Beside the archives the hand-written config.json already keeps there
    database = "${stateDir}/urls.sqlite3";
    downloadedMarker = "${stateDir}/files-downloaded";
    resolvedMarker = "${stateDir}/urls-resolved";

    # Resolves the browsable page a downloaded post came from; extend the per-site rules as new sites come up.
    recorder = pkgs.writeText "blockurl-record.py" ''
        """Record the page URL behind each file gallery-dl downloads, as a gallery-dl hook or as a script taking URLs."""

        import os
        import sqlite3

        DB = "${database}"
        DOWNLOADED = "${downloadedMarker}"
        RESOLVED = "${resolvedMarker}"

        _connection = None


        def connection():
            """Open the URL database once per run, creating it on first use."""
            global _connection
            if _connection is None:
                os.makedirs(os.path.dirname(DB), exist_ok=True)
                _connection = sqlite3.connect(DB, timeout=60)
                _connection.execute(
                    "CREATE TABLE IF NOT EXISTS urls (url TEXT PRIMARY KEY, sent INTEGER NOT NULL DEFAULT 0)"
                )
                _connection.commit()
            return _connection


        def touch(path):
            """Rewrite a marker so the wrapper can see this run reached it."""
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as handle:
                handle.write("\n")


        def remember(url):
            """Add a URL to the database, and mark that this run resolved one."""
            con = connection()
            con.execute("INSERT OR IGNORE INTO urls (url) VALUES (?)", (url,))
            con.commit()
            # Touched even for a URL already held, so a repeat run still counts as having resolved one.
            touch(RESOLVED)


        def page_url(kwdict):
            """Return the page a post is browsable at, or None when the site exposes no such field."""
            for key in ("post_url", "webpage_url", "gallery_url"):
                url = kwdict.get(key)
                if url:
                    return url
            category = kwdict.get("category")
            if category == "reddit" and kwdict.get("permalink"):
                return "https://www.reddit.com" + kwdict["permalink"]
            if category == "twitter" and kwdict.get("tweet_id"):
                author = kwdict.get("author") or kwdict.get("user") or {}
                if author.get("name"):
                    return "https://x.com/%s/status/%s" % (author["name"], kwdict["tweet_id"])
            return None


        def record(kwdict):
            """Download hook: note the page behind a finished file, leaving the sync timer to send it on."""
            touch(DOWNLOADED)
            url = page_url(kwdict)
            if url:
                remember(url)


        if __name__ == "__main__":
            import sys

            for argument in sys.argv[1:]:
                remember(argument)
    '';

    # Falls back to the URL handed to gallery-dl when files were downloaded but none exposed a page, which is all a booru or a forum offers.
    galleryDl = pkgs.writeShellApplication {
        name = "gallery-dl";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
            downloaded=${lib.escapeShellArg downloadedMarker}
            resolved=${lib.escapeShellArg resolvedMarker}

            stamp() {
                if [ -e "$1" ]; then stat -c %y "$1"; else echo none; fi
            }

            # Both markers are needed: --simulate and --dump-json exit 0 without running a single hook, and must not block the page.
            downloaded_before=$(stamp "$downloaded")
            resolved_before=$(stamp "$resolved")
            status=0
            ${pkgs.gallery-dl}/bin/gallery-dl "$@" || status=$?

            if [ "$status" -eq 0 ] &&
               [ "$(stamp "$downloaded")" != "$downloaded_before" ] &&
               [ "$(stamp "$resolved")" = "$resolved_before" ]; then
                for argument in "$@"; do
                    case "$argument" in
                        http://*|https://*) ${pkgs.python3}/bin/python3 ${recorder} "$argument" ;;
                        *) ;;
                    esac
                done
            fi

            exit "$status"
        '';
    };

    sync = pkgs.writers.writePython3Bin "gallery-dl-blockurl-sync" { flakeIgnore = [ "E501" ]; } ''
        import json
        import os
        import sqlite3
        import sys
        import urllib.error
        import urllib.request

        API = "${apiUrl}"
        KEY_FILE = "${apiKeyFile}"
        DB = "${database}"
        BATCH = 1000


        def api_key():
            """Read the key out of the NAME=value line the secret is stored as."""
            line = open(KEY_FILE, encoding="utf-8").read().strip()
            return line.partition("=")[2] if "=" in line else line


        def block(key, urls):
            """Send one batch of URLs to BlockURL."""
            request = urllib.request.Request(
                API + "/urls/block",
                data=json.dumps({"urls": urls}).encode(),
                headers={"Content-Type": "application/json", "X-API-Key": key},
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=60) as response:
                response.read()


        def main():
            if not os.path.exists(DB):
                print("nothing downloaded yet", flush=True)
                return
            con = sqlite3.connect(DB, timeout=60)
            urls = [row[0] for row in con.execute("SELECT url FROM urls WHERE sent = 0")]
            sent = 0
            for index in range(0, len(urls), BATCH):
                batch = urls[index:index + BATCH]
                block(api_key(), batch)
                # Marked a batch at a time, so a failure part way through does not resend what BlockURL already took.
                con.executemany("UPDATE urls SET sent = 1 WHERE url = ?", [(url,) for url in batch])
                con.commit()
                sent += len(batch)
            con.close()
            print("blocked", sent, "new URLs", flush=True)


        try:
            main()
        except (urllib.error.URLError, OSError, sqlite3.Error) as error:
            print("blockurl sync failed:", error, file=sys.stderr, flush=True)
            sys.exit(1)
    '';
in
{
    config = lib.mkMerge [

        # BlockURL API Key ###########################################################################################################################
        {
            # Heimdall's own copy of this key lives in 2-server/blockurl.nix; .sops.yaml names Odin as a second recipient of the file.
            sops.secrets.blockurl_api_key = {
                sopsFile = "${config.technet.secrets.root}/2-server/blockurl.yaml";
                owner = "beatlink";
                mode = "0400";
            };
        }

        # Gallery-DL #################################################################################################################################
        {
            # gallery-dl merges /etc over its own hand-written config.json, so the recorder is added without Nix owning that file.
            environment.etc."gallery-dl.conf".source = (pkgs.formats.json { }).generate "gallery-dl.conf" {
                extractor.postprocessors = [
                    {
                        name = "python";
                        event = "after"; # Only this hook runs past finalize(); "post" fires before a byte is downloaded
                        function = "${recorder}:record";
                    }
                ];
            };

            home-manager.users.beatlink = {
                programs.gallery-dl = {
                    enable = true;
                    package = galleryDl;
                };

                home.persistence."/Storage/Apps/Tools/Gallery-DL".directories = [
                    ".config/gallery-dl"
                ];
            };
        }

        # BlockURL Sync ##############################################################################################################################
        {
            home-manager.users.beatlink = {
                home.packages = [ sync ];

                systemd.user.services.gallery-dl-blockurl-sync = {
                    Unit.Description = "Send the pages gallery-dl downloaded from to BlockURL";
                    Service = {
                        Type = "oneshot";
                        ExecStart = lib.getExe sync;
                    };
                };

                systemd.user.timers.gallery-dl-blockurl-sync = {
                    Unit.Description = "Daily BlockURL sync of gallery-dl downloads";
                    Timer = {
                        OnCalendar = "daily";
                        Persistent = true; # The laptop is asleep at most fixed times, so the run has to be caught up rather than missed
                        RandomizedDelaySec = "30m";
                    };
                    Install.WantedBy = [ "timers.target" ];
                };
            };
        }
    ];
}
